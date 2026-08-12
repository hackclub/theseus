# frozen_string_literal: true

class SettingsController < ApplicationController
  skip_after_action :verify_authorized

  def show
    render Views::Settings::Show.new(user: current_user)
  end

  def update
    settings = params.fetch(:settings, {}).permit(:czar_po_emails)
    current_user.update_setting("czar_po_emails", settings[:czar_po_emails] == "1")
    redirect_to settings_path, notice: "Settings saved."
  end
end
