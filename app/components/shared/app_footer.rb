# frozen_string_literal: true

class Components::Shared::AppFooter < Components::Base
  def view_template
    footer(class: "app-footer") do
      span(class: "footer-rev") { "rev #{Rails.application.config.git_version}" }
    end
  end
end
