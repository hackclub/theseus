# frozen_string_literal: true

require "rails_helper"

RSpec.describe "the sidebar", type: :request do
  it "renders one mobile toggle, the overlay, and the script that opens them" do
    user = create(:user)
    fake_hcb!
    sign_in_as(user)
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body.scan(/class="sidebar-toggle btn-sm"/).size).to eq(1)
    expect(response.body).to include(%(class="sidebar-overlay"))
    expect(response.body).to include("classList.add('open')")
  end

  it "has scss for the open class the toggle sets" do
    css = Rails.root.join("app/frontend/styles/theseus.scss").read
    mobile = css[/@media \(max-width: 60rem\) \{.*?\n\}/m]

    expect(mobile).to include(".theseus-sidebar")
    expect(mobile).to include(".sidebar-overlay")
    expect(mobile.scan("&.open").size).to eq(2)
  end

  describe "sidebar navigation links" do
    let(:user) { create(:user) }

    before do
      fake_hcb!
      sign_in_as(user)
    end

    it "renders Home link" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('href="/"')
      expect(response.body).to include(">Home<")
    end

    it "renders Tasks link" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tasks_path)
    end

    it "renders Mail section links" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mail")
      expect(response.body).to include(letters_path)
      expect(response.body).to include(letter_batches_path)
    end

    it "renders Warehouse section links for warehouse users" do
      user.update(can_warehouse: true)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Warehouse")
      expect(response.body).to include(warehouse_orders_path)
      expect(response.body).to include(warehouse_skus_path)
    end

    it "renders Settings section links" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Settings")
      expect(response.body).to include(settings_path)
      expect(response.body).to include(hcb_payment_accounts_path)
    end

    it "renders API section links" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("API")
      expect(response.body).to include(api_keys_path)
      expect(response.body).to include(api_docs_path)
    end

    it "renders Accounting section with Tags link" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Accounting")
      expect(response.body).to include(tags_path)
    end
  end

  describe "sidebar gating" do
    let(:user) { create(:user) }

    before do
      fake_hcb!
      sign_in_as(user)
    end

    it "shows warehouse section to warehouse users" do
      user.update(can_warehouse: true)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Warehouse")
    end

    it "does not show admin section to non-admin users" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Admin")
      expect(response.body).not_to include(admin_users_path)
    end

    it "shows admin section only to admin users" do
      admin = create_admin
      sign_in_as(admin)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin")
      expect(response.body).to include(admin_users_path)
      expect(response.body).to include(admin_common_tags_path)
    end

    it "shows Approvals badge link only to warehouse czar" do
      user.update(can_warehouse: true, is_warehouse_czar: false)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Approvals")

      user.update(is_warehouse_czar: true)
      sign_in_as(user)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Approvals")
    end
  end

  describe "command palette (kbar)" do
    let(:user) { create(:user) }

    before do
      fake_hcb!
      sign_in_as(user)
    end

    it "includes kbar data script for authenticated users" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="kbar-data"')
      expect(response.body).to include('type="application/json"')
    end

    it "includes kbar trigger button in action bar" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="kbar-trigger"')
      expect(response.body).to include("⌘K")
    end

    it "includes command-palette Svelte component div" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-svelte-component="command-palette"')
    end

    it "does not render kbar for unauthenticated users" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      get root_path
      expect(response.body).not_to include('id="kbar-data"')
    end
  end

  describe "keyboard shortcuts" do
    let(:user) { create(:user) }

    before do
      fake_hcb!
      sign_in_as(user)
    end

    it "includes keyboard-shortcuts-data script for authenticated users" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="keyboard-shortcuts-data"')
    end

    it "includes keyboard-shortcuts Svelte component div" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-svelte-component="keyboard-shortcuts"')
    end

    it "includes hints-modal Svelte component div" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-svelte-component="hints-modal"')
    end

    it "does not render keyboard shortcuts for unauthenticated users" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      get root_path
      expect(response.body).not_to include('id="keyboard-shortcuts-data"')
    end
  end

  describe "action bar" do
    let(:user) { create(:user) }

    before do
      fake_hcb!
      sign_in_as(user)
    end

    it "renders user context in action bar" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("user-menu-username")
    end

    it "renders user menu button" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="popover"')
    end

    it "renders logout button in user menu" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(signout_path)
      expect(response.body).to include("Log out")
    end

    it "renders hints button" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('onclick="window.openHints')
      expect(response.body).to include(">?<")
    end

    it "renders brand/logo link to root" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('href="/"')
      expect(response.body).to include(">Theseus<")
    end
  end

  describe "flash messages" do
    let(:user) { create(:user) }

    before do
      fake_hcb!
      sign_in_as(user)
    end

    it "renders flash partial in layout" do
      # Trigger a flash by posting something that sets one
      post set_as_home_return_address_path(create(:return_address, user: user))
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end
end
