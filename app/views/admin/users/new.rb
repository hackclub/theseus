# frozen_string_literal: true

class Views::Admin::Users::New < Views::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "New User")
    render Components::Admin::Users::Form.new(user: @user)
  end
end
