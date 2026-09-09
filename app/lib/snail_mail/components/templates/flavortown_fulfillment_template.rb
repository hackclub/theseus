# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class FlavortownFulfillmentTemplate < TemplateBase
        def self.template_name
          "flavortown fulfillment"
        end

        def self.template_description
          "Flavortown Fulfillment"
        end

        def self.show_on_single?
          true
        end

        def view_template

          image(
            image_path("flavortown/chefs.png"),
            at: [46, 260],
            width: 340,
          )

          # Render return address
          render_return_address(10, 278, 260, 70, size: 10)

          # Render destination address
          render_destination_address(
            120,
            155,
            200,
            55,
            size: 12,
            valign: :center,
            align: :left
          )

          # Render postal elements
          render_imb(240, 24, 183)
          render_qr_code(5, 65, 60)
          render_letter_id(10, 19, 10)

          render_postage
        end

      end
    end
  end
end
