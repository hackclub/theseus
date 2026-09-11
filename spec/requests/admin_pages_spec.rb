# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin pages", type: :request do
  let(:admin) { create_admin }

  before do
    fake_hcb!
    sign_in_as(admin)
    # Engine mounts sit behind AdminConstraint which needs session access
    allow(AdminConstraint).to receive(:matches?).and_return(true)
  end

  describe "Common tags" do
    it "renders common tags index" do
      tag1 = CommonTag.create!(tag: "urgent")
      tag2 = CommonTag.create!(tag: "bulk")

      get admin_common_tags_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("urgent")
      expect(response.body).to include("bulk")
    end

    it "shows the new tag form" do
      get new_admin_common_tag_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tag")
    end

    it "creates a new common tag" do
      expect {
        post admin_common_tags_path, params: {
          common_tag: {
            tag: "express",
            implies_ysws: true
          }
        }
      }.to change(CommonTag, :count).by(1)

      expect(response).to redirect_to(admin_common_tags_path)
      expect(CommonTag.last.tag).to eq("express")
      expect(CommonTag.last.implies_ysws?).to be true
    end


    it "shows the edit form for a common tag" do
      tag = CommonTag.create!(tag: "standard")

      get edit_admin_common_tag_path(tag)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("standard")
    end

    it "updates a common tag" do
      tag = CommonTag.create!(tag: "old-tag", implies_ysws: false)

      patch admin_common_tag_path(tag), params: {
        common_tag: {
          tag: "new-tag",
          implies_ysws: true
        }
      }

      expect(response).to redirect_to(admin_common_tags_path)
      tag.reload
      expect(tag.tag).to eq("new-tag")
      expect(tag.implies_ysws?).to be true
    end

    it "deletes a common tag" do
      tag = CommonTag.create!(tag: "deleteme")

      expect {
        delete admin_common_tag_path(tag)
      }.to change(CommonTag, :count).by(-1)

      expect(response).to redirect_to(admin_common_tags_path)
    end
  end

  describe "USPS Mailer IDs" do
    it "renders mailer IDs index" do
      mid1 = create(:usps_mailer_id, name: "Acme Corp", crid: "1234", mid: "567890")
      mid2 = create(:usps_mailer_id, name: "Beta Inc", crid: "5678", mid: "123456")

      get admin_usps_mailer_ids_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme Corp")
      expect(response.body).to include("Beta Inc")
    end

    it "shows a mailer ID" do
      mid = create(:usps_mailer_id, name: "Test Corp", crid: "1234", mid: "567890")

      get admin_usps_mailer_id_path(mid)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Corp")
      expect(response.body).to include("1234")
      expect(response.body).to include("567890")
    end

    it "shows the new mailer ID form" do
      get new_admin_usps_mailer_id_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mailer ID")
    end

    it "creates a new mailer ID" do
      expect {
        post admin_usps_mailer_ids_path, params: {
          usps_mailer_id: {
            name: "New Mailer",
            crid: "9999",
            mid: "111111"
          }
        }
      }.to change(USPS::MailerId, :count).by(1)

      expect(response).to redirect_to(admin_usps_mailer_ids_path)
      new_mid = USPS::MailerId.last
      expect(new_mid.name).to eq("New Mailer")
      expect(new_mid.crid).to eq("9999")
      expect(new_mid.mid).to eq("111111")
    end

    it "shows the edit form for a mailer ID" do
      mid = create(:usps_mailer_id, name: "Edit Me", crid: "4444", mid: "555555")

      get edit_admin_usps_mailer_id_path(mid)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit Me")
    end

    it "updates a mailer ID" do
      mid = create(:usps_mailer_id, name: "Old Name", crid: "1111", mid: "222222")

      patch admin_usps_mailer_id_path(mid), params: {
        usps_mailer_id: {
          name: "Updated Name",
          crid: "3333",
          mid: "444444"
        }
      }

      expect(response).to redirect_to(admin_usps_mailer_id_path(mid))
      mid.reload
      expect(mid.name).to eq("Updated Name")
      expect(mid.crid).to eq("3333")
      expect(mid.mid).to eq("444444")
    end
  end

  describe "USPS Payment Accounts" do
    let(:mailer_id) { create(:usps_mailer_id, name: "Default", crid: "1234", mid: "567890") }

    it "renders payment accounts index" do
      account1 = create(:usps_payment_account, name: "Account 1", usps_mailer_id: mailer_id)
      account2 = create(:usps_payment_account, name: "Account 2", usps_mailer_id: mailer_id)

      get admin_usps_payment_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Account 1")
      expect(response.body).to include("Account 2")
    end

    it "shows a payment account" do
      account = create(:usps_payment_account, name: "Test Account", usps_mailer_id: mailer_id)

      get admin_usps_payment_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Account")
    end

    it "shows the new payment account form" do
      get new_admin_usps_payment_account_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Payment Account")
    end

    it "creates a new EPS payment account" do
      expect {
        post admin_usps_payment_accounts_path, params: {
          usps_payment_account: {
            name: "New EPS Account",
            account_type: "EPS",
            account_number: "1234567890",
            usps_mailer_id_id: mailer_id.id
          }
        }
      }.to change(USPS::PaymentAccount, :count).by(1)

      expect(response).to redirect_to(admin_usps_payment_accounts_path)
      account = USPS::PaymentAccount.last
      expect(account.name).to eq("New EPS Account")
      expect(account.EPS?).to be true
      expect(account.account_number).to eq("1234567890")
    end

    it "creates a new PERMIT payment account" do
      expect {
        post admin_usps_payment_accounts_path, params: {
          usps_payment_account: {
            name: "New Permit Account",
            account_type: "PERMIT",
            permit_number: "123456",
            permit_zip: "12345",
            usps_mailer_id_id: mailer_id.id
          }
        }
      }.to change(USPS::PaymentAccount, :count).by(1)

      expect(response).to redirect_to(admin_usps_payment_accounts_path)
      account = USPS::PaymentAccount.last
      expect(account.name).to eq("New Permit Account")
      expect(account.PERMIT?).to be true
      expect(account.permit_number).to eq("123456")
      expect(account.permit_zip).to eq("12345")
    end

    it "shows the edit form for a payment account" do
      account = create(:usps_payment_account, name: "Edit Me", usps_mailer_id: mailer_id)

      get edit_admin_usps_payment_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit Me")
    end

    it "updates a payment account" do
      account = create(:usps_payment_account, name: "Old Name", usps_mailer_id: mailer_id)

      patch admin_usps_payment_account_path(account), params: {
        usps_payment_account: {
          name: "Updated Name",
          account_type: "EPS",
          account_number: "9999999999",
          usps_mailer_id_id: mailer_id.id
        }
      }

      expect(response).to redirect_to(admin_usps_payment_account_path(account))
      account.reload
      expect(account.name).to eq("Updated Name")
      expect(account.account_number).to eq("9999999999")
    end
  end

  describe "Engine mounts" do
    it "loads the GoodJob dashboard" do
      get "/back_office/good_job"
      expect(response).not_to have_http_status(:internal_server_error)
    end

    it "loads the Flipper UI" do
      get "/back_office/flipper"
      expect(response).not_to have_http_status(:internal_server_error)
    end

    it "loads the Blazer dashboard" do
      get "/back_office/blazer"
      expect(response).not_to have_http_status(:internal_server_error)
    end
  end
end
