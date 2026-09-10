# frozen_string_literal: true

require "rails_helper"

RSpec.describe "letter queues", type: :request do
  let(:owner) { create(:user) }
  let(:admin) { create_admin }

  FORM_ENCODED = { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }.freeze

  def build_queue(user, **attrs)
    Letter::Queue.create!(
      {
        user: user, name: "Batch queue", tags: [ "smoke" ],
        letter_height: 1, letter_width: 1, letter_weight: 1,
        letter_processing_category: "letter",
        letter_mailer_id: user.home_mid,
        letter_return_address: user.home_return_address
      }.merge(attrs)
    )
  end

  def queue_params(**overrides)
    {
      name: "Batch queue", tags: [ "smoke" ],
      letter_height: 1, letter_width: 1, letter_weight: 1,
      letter_processing_category: "letter"
    }.merge(overrides)
  end

  def build_instant_queue(user, **attrs)
    Letter::InstantQueue.create!(
      {
        user: user, name: "Instant queue", tags: [ "smoke" ],
        template: "hackatime_template", postage_type: "stamps",
        letter_height: 1, letter_width: 1, letter_weight: 1,
        letter_processing_category: "letter",
        letter_mailer_id: user.home_mid,
        letter_return_address: user.home_return_address
      }.merge(attrs)
    )
  end

  # Rack keeps the last value for a repeated key, which is what makes the order
  # of the hidden field and the checkbox matter.
  def instant_queue_body(*pairs)
    base = [
      [ "name", "Instant queue" ],
      [ "tags[]", "smoke" ],
      [ "template", "hackatime_template" ],
      [ "postage_type", "stamps" ],
      [ "letter_height", "1" ],
      [ "letter_width", "1" ],
      [ "letter_weight", "1" ],
      [ "letter_processing_category", "letter" ]
    ]
    (base + pairs).map { |k, v| "letter_instant_queue[#{CGI.escape(k)}]=#{CGI.escape(v.to_s)}" }.join("&")
  end

  before { fake_hcb! }

  describe "the QR code checkbox" do
    let(:queue) { build_instant_queue(owner, include_qr_code: true) }

    before { sign_in_as(owner) }

    it "saves an unchecked box as off" do
      patch letter_instant_queue_path(queue),
            params: instant_queue_body([ "include_qr_code", "0" ]),
            headers: FORM_ENCODED

      expect(queue.reload.include_qr_code).to be false
    end

    it "saves a checked box as on even though the hidden field shares its name" do
      queue.update!(include_qr_code: false)

      patch letter_instant_queue_path(queue),
            params: instant_queue_body([ "include_qr_code", "0" ], [ "include_qr_code", "1" ]),
            headers: FORM_ENCODED

      expect(queue.reload.include_qr_code).to be true
    end

    it "renders the hidden field before the checkbox" do
      get edit_letter_instant_queue_path(queue)

      hidden = response.body.index(%(type="hidden" name="letter_instant_queue[include_qr_code]"))
      box = response.body.index(%(type="checkbox" name="letter_instant_queue[include_qr_code]"))

      expect(hidden).not_to be_nil
      expect(box).not_to be_nil
      expect(hidden).to be < box
    end
  end

  describe "the admin slug field" do
    let(:queue) { build_queue(owner) }

    it "lets an admin rename the slug" do
      sign_in_as(admin)

      patch letter_queue_path(queue), params: { letter_queue: queue_params(slug: "renamed") }

      expect(queue.reload.slug).to eq("renamed")
    end

    it "ignores a slug from a non-admin" do
      sign_in_as(owner)
      before_slug = queue.slug

      patch letter_queue_path(queue), params: { letter_queue: queue_params(slug: "renamed") }

      expect(queue.reload.slug).to eq(before_slug)
    end

    it "lets an admin rename an instant queue slug" do
      instant = build_instant_queue(owner)
      sign_in_as(admin)

      patch letter_instant_queue_path(instant), params: {
        letter_instant_queue: queue_params(slug: "renamed-instant", template: "hackatime_template", postage_type: "stamps")
      }

      expect(instant.reload.slug).to eq("renamed-instant")
    end

    it "ignores an instant queue slug from a non-admin" do
      instant = build_instant_queue(owner)
      sign_in_as(owner)
      before_slug = instant.slug

      patch letter_instant_queue_path(instant), params: {
        letter_instant_queue: queue_params(slug: "renamed-instant", template: "hackatime_template", postage_type: "stamps")
      }

      expect(instant.reload.slug).to eq(before_slug)
    end
  end

  describe "the return address" do
    let(:queue) { build_queue(owner) }
    let(:someone_else) { create(:user) }
    let(:private_address) { create(:return_address, user: someone_else, shared: false) }
    let(:shared_address) { create(:return_address, user: someone_else, shared: true) }
    let(:own_address) { create(:return_address, user: owner, shared: false) }

    it "refuses another user's private address" do
      sign_in_as(owner)
      before_id = queue.letter_return_address_id

      patch letter_queue_path(queue), params: { letter_queue: queue_params(letter_return_address_id: private_address.id) }

      expect(queue.reload.letter_return_address_id).to eq(before_id)
    end

    it "accepts a shared address" do
      sign_in_as(owner)

      patch letter_queue_path(queue), params: { letter_queue: queue_params(letter_return_address_id: shared_address.id) }

      expect(queue.reload.letter_return_address_id).to eq(shared_address.id)
    end

    it "accepts the user's own address" do
      sign_in_as(owner)

      patch letter_queue_path(queue), params: { letter_queue: queue_params(letter_return_address_id: own_address.id) }

      expect(queue.reload.letter_return_address_id).to eq(own_address.id)
    end

    it "lets an admin pick anything" do
      sign_in_as(admin)

      patch letter_queue_path(queue), params: { letter_queue: queue_params(letter_return_address_id: private_address.id) }

      expect(queue.reload.letter_return_address_id).to eq(private_address.id)
    end

    it "refuses another user's private address on an instant queue" do
      instant = build_instant_queue(owner)
      sign_in_as(owner)
      before_id = instant.letter_return_address_id

      patch letter_instant_queue_path(instant), params: {
        letter_instant_queue: queue_params(letter_return_address_id: private_address.id, template: "hackatime_template", postage_type: "stamps")
      }

      expect(instant.reload.letter_return_address_id).to eq(before_id)
    end
  end

  describe "the show page" do
    before { sign_in_as(owner) }

    it "documents the batch queue API endpoint" do
      queue = build_queue(owner)

      get letter_queue_path(queue)

      expect(response.body).to include("API docs")
      expect(response.body).to include(api_v1_letter_queue_path(queue))
      expect(response.body).to include("idempotency_key")
      expect(response.body).to include(api_keys_path)
    end

    it "documents the instant queue API endpoint" do
      instant = build_instant_queue(owner)

      get letter_instant_queue_path(instant)

      expect(response.body).to include(create_instant_letter_api_v1_letter_queues_path(instant))
    end
  end

  describe "the index page" do
    it "does not nest a button inside the bulk-mark button_to" do
      sign_in_as(admin)

      get letter_queues_path

      expect(response.body).to include("Mark printed instants mailed")
      expect(response.body).not_to match(/<button[^>]*>\s*<button/)
    end
  end
end
