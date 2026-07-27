# frozen_string_literal: true

require "rails_helper"

RSpec.describe BatchProcessJob, type: :job do
  # Shared setup: a batch in `fields_mapped` state with letters that have indicia postage.
  # External services (USPS API, HCB transfers) are stubbed; DB operations are real.

  let(:mailer_id) { create(:usps_mailer_id) }
  let(:return_address) { create(:return_address) }
  let(:user) { create(:user, home_mid: mailer_id, home_return_address: return_address) }
  let(:batch) do
    create(:letter_batch, user: user, mailer_id: mailer_id,
           letter_mailing_date: 1.week.from_now.to_date).tap do |b|
      b.mark_fields_mapped!
    end
  end
  let(:usps_account) { create(:usps_payment_account, usps_mailer_id: mailer_id) }
  let(:hcb_oauth) { create(:hcb_oauth_connection, user: user) }
  let(:hcb_account) { create(:hcb_payment_account, user: user, oauth_connection: hcb_oauth) }

  let(:process_options) do
    {
      us_postage_type: "indicia",
      intl_postage_type: "international_origin",
      usps_payment_account_id: usps_account.id,
      hcb_payment_account_id: hcb_account.id,
    }
  end

  # Creates n letters attached to the batch with US addresses
  def create_letters(count = 3, address_attrs: {}, letter_attrs: {})
    count.times.map do
      addr = create(:address, **address_attrs)
      create(:letter,
        batch: batch,
        user: user,
        usps_mailer_id: mailer_id,
        return_address: return_address,
        address: addr,
        height: batch.letter_height,
        width: batch.letter_width,
        weight: batch.letter_weight,
        processing_category: "letter",
        postage_type: "stamps",
        mailing_date: batch.letter_mailing_date,
        **letter_attrs,
      )
    end
  end

  # Fake transfer object returned by HCB::TransferService#call
  let(:fake_transfer) { OpenStruct.new(id: "txn_fake_123") }
  let(:fake_payment_token) { "tok_fake_abc" }

  before do
    batch.update!(process_options: process_options)

    # Stub external services
    allow_any_instance_of(HCB::TransferService).to receive(:call).and_return(fake_transfer)
    allow(USPS::PaymentAccount).to receive(:find).with(usps_account.id).and_return(usps_account)
    allow(usps_account).to receive(:create_payment_token).and_return(fake_payment_token)
    allow(HCB::PaymentAccount).to receive(:find).with(hcb_account.id).and_return(hcb_account)
    allow(HCB::PaymentAccount).to receive(:refund_to_organization!).and_return(true)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(batch).to receive(:generate_labels)
    # Stub Letter::Batch.find to return our batch instance (so generate_labels stub works)
    allow(Letter::Batch).to receive(:find).with(batch.id).and_return(batch)
  end

  def stub_buy_success(cost: 0.68)
    allow_any_instance_of(USPS::Indicium).to receive(:buy!) do |indicium, _token|
      indicium.update!(
        postage: cost,
        fees: 0.0,
        raw_json_response: { "indiciaMetadata" => { "postage" => cost, "fees" => [], "SKU" => "FAKE" } },
      )
    end
  end

  def perform_job
    described_class.new.perform(batch.id)
  end

  describe "idempotency — skips already-processed batches" do
    it "returns immediately when batch is already processed" do
      batch.mark_generating_labels!
      batch.mark_processed!

      expect_any_instance_of(HCB::TransferService).not_to receive(:call)
      perform_job
    end
  end

  describe "phase 1: configure_letters" do
    it "sets postage_type and mailing_date on each letter based on process_options" do
      letters = create_letters(2)
      stub_buy_success

      perform_job

      letters.each do |l|
        l.reload
        expect(l.postage_type).to eq("indicia")
        expect(l.mailing_date).to eq(batch.letter_mailing_date)
      end
    end

    it "sets international letters to intl_postage_type" do
      intl_letter = create_letters(1, address_attrs: { country: "GB", state: "London", postal_code: "SW1A 1AA" }).first
      stub_buy_success

      perform_job

      intl_letter.reload
      expect(intl_letter.postage_type).to eq("international_origin")
    end
  end

  describe "phase 2: purchase indicia" do
    context "state transitions" do
      it "transitions through purchasing → generating_labels → processed" do
        create_letters(1)
        stub_buy_success

        states = []
        allow(batch).to receive(:mark_purchasing!) { states << :purchasing; batch.aasm.fire!(:mark_purchasing) }
        allow(batch).to receive(:mark_generating_labels!) { states << :generating_labels; batch.aasm.fire!(:mark_generating_labels) }
        allow(batch).to receive(:mark_processed!) { states << :processed; batch.aasm.fire!(:mark_processed) }

        perform_job

        expect(states).to eq([:purchasing, :generating_labels, :processed])
      end
    end

    context "HCB transfer" do
      it "calls HCB::TransferService with estimated cost" do
        letters = create_letters(2)
        stub_buy_success

        transfer_service = instance_double(HCB::TransferService, call: fake_transfer)
        allow(HCB::TransferService).to receive(:new).and_return(transfer_service)

        perform_job

        expect(HCB::TransferService).to have_received(:new).with(
          hcb_payment_account: hcb_account,
          amount_cents: anything,
          name: "Postage for #{batch.public_id}",
          memo: "[theseus] batch postage",
        )
        expect(transfer_service).to have_received(:call)
      end

      it "raises when HCB transfer fails" do
        create_letters(1)
        stub_buy_success

        allow_any_instance_of(HCB::TransferService).to receive(:call).and_return(false)

        expect { perform_job }.to raise_error("HCB transfer failed")
      end
    end

    context "per-letter indicia purchase" do
      it "creates USPS::Indicium for each letter needing indicia" do
        letters = create_letters(3)
        stub_buy_success

        perform_job

        letters.each do |l|
          l.reload
          expect(l.usps_indicium).to be_present
          expect(l.indicia_state).to eq("purchased")
        end
      end

      it "sets indicia_state to 'purchased' on success" do
        letter = create_letters(1).first
        stub_buy_success

        perform_job

        letter.reload
        expect(letter.indicia_state).to eq("purchased")
        expect(letter.usps_indicium.postage).to be_positive
      end

      it "sets indicia_state to 'failed' with error message on per-letter failure" do
        letters = create_letters(2)
        call_count = 0

        allow_any_instance_of(USPS::Indicium).to receive(:buy!) do |indicium, _token|
          call_count += 1
          if call_count == 1
            indicium.update!(postage: 0.68, fees: 0.0, raw_json_response: { "indiciaMetadata" => { "postage" => 0.68, "fees" => [], "SKU" => "FAKE" } })
          else
            raise "USPS service unavailable"
          end
        end

        allow(Sentry).to receive(:capture_exception)

        perform_job

        states = letters.map { |l| l.reload; l.indicia_state }
        expect(states).to include("purchased")
        expect(states).to include("failed")

        failed_letter = letters.find { |l| l.reload; l.indicia_state == "failed" }
        expect(failed_letter.indicia_error).to include("USPS service unavailable")
      end

      it "does NOT wrap purchases in a transaction (failures are per-letter)" do
        letters = create_letters(3)
        purchase_order = []

        allow_any_instance_of(USPS::Indicium).to receive(:buy!) do |indicium, _token|
          purchase_order << indicium.letter_id
          if purchase_order.size == 2
            raise "boom on letter 2"
          end
          indicium.update!(postage: 0.68, fees: 0.0, raw_json_response: { "indiciaMetadata" => { "postage" => 0.68, "fees" => [], "SKU" => "FAKE" } })
        end

        allow(Sentry).to receive(:capture_exception)

        perform_job

        # The first letter's purchase persists even though a later letter failed
        purchased = letters.select { |l| l.reload; l.indicia_state == "purchased" }
        failed = letters.select { |l| l.reload; l.indicia_state == "failed" }
        expect(purchased.size).to eq(2)
        expect(failed.size).to eq(1)
      end
    end

    context "idempotency — skips already-purchased letters" do
      it "skips letters with indicia_state 'purchased'" do
        letter = create_letters(1).first
        stub_buy_success

        # Simulate already purchased
        letter.update_columns(indicia_state: "purchased")

        expect_any_instance_of(USPS::Indicium).not_to receive(:buy!)

        perform_job
      end

      it "skips letters that already have a usps_indicium record" do
        letter = create_letters(1).first
        # Pre-create an indicium with postage (already bought)
        USPS::Indicium.create!(
          letter: letter,
          payment_account: usps_account,
          mailing_date: batch.letter_mailing_date,
          postage: 0.68,
          fees: 0.0,
          raw_json_response: {},
        )
        letter.update_columns(indicia_state: "purchased")

        expect_any_instance_of(USPS::Indicium).not_to receive(:buy!)

        perform_job
      end
    end

    context "token refresh on Faraday::UnauthorizedError" do
      it "refreshes payment token and retries once" do
        letter = create_letters(1).first
        attempt = 0

        allow_any_instance_of(USPS::Indicium).to receive(:buy!) do |indicium, token|
          attempt += 1
          if attempt == 1
            raise Faraday::UnauthorizedError, "401 Unauthorized"
          end
          indicium.update!(postage: 0.68, fees: 0.0, raw_json_response: { "indiciaMetadata" => { "postage" => 0.68, "fees" => [], "SKU" => "FAKE" } })
        end

        perform_job

        letter.reload
        expect(letter.indicia_state).to eq("purchased")
        # create_payment_token: once at start + once on refresh
        expect(usps_account).to have_received(:create_payment_token).at_least(:twice)
      end

      it "records failure if retry also fails" do
        letter = create_letters(1).first

        allow_any_instance_of(USPS::Indicium).to receive(:buy!).and_raise(Faraday::UnauthorizedError, "401 Unauthorized")
        allow(Sentry).to receive(:capture_exception)

        perform_job

        letter.reload
        expect(letter.indicia_state).to eq("failed")
        expect(letter.indicia_error).to include("401")
        expect(Sentry).to have_received(:capture_exception).with(
          an_instance_of(Faraday::UnauthorizedError),
          hash_including(tags: { money: true }),
        )
      end
    end
  end

  describe "broadcasting" do
    it "broadcasts cell updates for each letter" do
      letters = create_letters(2)
      stub_buy_success

      perform_job

      letters.each do |l|
        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
          batch, :progress,
          hash_including(target: "cell-#{l.id}"),
        ).at_least(:once)
      end
    end

    it "broadcasts summary updates across phases" do
      create_letters(1)
      stub_buy_success

      perform_job

      # purchasing phase summary
      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        batch, :progress,
        hash_including(target: "batch-summary", partial: "letter/batches/grid_summary"),
      ).at_least(3).times # purchasing start, per-letter update(s), generating_labels, done
    end
  end

  describe "phase 3: generate labels" do
    it "calls generate_labels and transitions to processed" do
      create_letters(1)
      # No indicia needed — stamps only
      batch.update!(process_options: process_options.merge(us_postage_type: "stamps"))

      perform_job

      expect(batch).to have_received(:generate_labels)
      expect(batch.reload.aasm_state).to eq("processed")
    end
  end

  describe "skips indicia phase when postage is stamps-only" do
    it "goes directly to generating_labels without purchasing" do
      create_letters(1)
      batch.update!(process_options: { us_postage_type: "stamps", intl_postage_type: "international_origin" })

      expect_any_instance_of(HCB::TransferService).not_to receive(:call)

      perform_job

      expect(batch.reload.aasm_state).to eq("processed")
    end
  end

  describe "batch records HCB transfer metadata" do
    it "stores hcb_payment_account and hcb_transfer_id after indicia purchase" do
      create_letters(1)
      stub_buy_success

      perform_job

      batch.reload
      expect(batch.hcb_payment_account_id).to eq(hcb_account.id)
      expect(batch.hcb_transfer_id).to eq("txn_fake_123")
    end
  end
end
