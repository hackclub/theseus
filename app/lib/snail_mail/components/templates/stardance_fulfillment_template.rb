# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class StardanceFulfillmentTemplate < TemplateBase
        def self.template_name
          "stardance fulfillment"
        end

        def self.template_description
          "Stardance Fulfillment"
        end

        def self.show_on_single?
          true
        end

        def view_template

          image(
            image_path("stardance/astronomical.png"),
            at: [ -2.5, 295 ],
            width: 443,
          )

          # Render return address
          render_return_address(10, 278, 260, 70, size: 10)

          if letter.rubber_stamps.present?
            font("arial") do
              text_box(
                letter.rubber_stamps,
                at: [ 7, 200 ],
                width: 100,
                height: 80,
                overflow: :shrink_to_fit,
                disable_wrap_by_char: true,
                min_size: 1
              )
            end
          end

          # Render destination address
          render_destination_address(
            130,
            170,
            230,
            55,
            size: 12,
            valign: :center,
            align: :center
          )

          # Render postal elements
          render_imb(240, 24, 183)
          render_qr_code(5, 120, 50)
          render_letter_id(10, 19, 10)

          render_postage
        end

      end
    end
  end
end
