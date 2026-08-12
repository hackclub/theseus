# frozen_string_literal: true

class Views::Admin::Users::Edit < Views::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "Edit #{@user.username || 'User'}")
    render Components::Admin::Users::Form.new(user: @user)
  end
end
