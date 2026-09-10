# frozen_string_literal: true

# Sessions are set by the Hack Club OAuth callback, which request specs can't
# drive, so log in by answering `current_user` directly.
module SignIn
  def sign_in_as(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  def create_admin(**attrs)
    create(:user, { is_admin: true, can_warehouse: true, is_warehouse_czar: true, can_use_indicia: true }.merge(attrs))
  end
end

RSpec.configure do |config|
  config.include SignIn, type: :request
end
