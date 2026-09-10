# frozen_string_literal: true

class Views::APIKeys::RevokeConfirm < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(api_key:)
    @api_key = api_key
  end

  def view_template
    div(class: "toolbar toolbar--flush") do
      div(class: "flex-row") do
        a(href: api_key_path(@api_key), class: "link-muted") { "← #{@api_key.pretty_name}" }
        strong(class: "text-title") { "Revoke API Key" }
      end
    end

    div(class: "show-layout") do
      div(class: "show-main") do
        section(class: "mb-1") do
          strong { "Revoking #{@api_key.pretty_name}" }
          hr
          div(class: "banner banner-error mt-half mb-1") do
            plain "This is irreversible. Everything that depends on the key "
            code { @api_key.abbreviated }
            plain " will stop working, and it can't be reactivated."
          end

          form_with url: revoke_api_key_path(@api_key), method: :post, local: true do
            div(class: "flex-row") do
              button(class: "btn-danger", type: "submit") { "Do it. Pull the trigger." }
              a(href: api_key_path(@api_key)) { "Cancel" }
            end
          end
        end
      end
    end
  end
end
