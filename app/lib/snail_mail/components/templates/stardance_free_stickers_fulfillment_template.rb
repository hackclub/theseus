# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class StardanceFreeStickersFulfillmentTemplate < TemplateBase
        def self.template_name
          "stardance free stickers fulfillment"
        end

        def self.template_description
          "Stardance Free Stickers Fulfillment"
        end

        def self.show_on_single?
          true
        end

        def view_template
          image(
            image_path("stardance/domain.png"),
            at: [ -2.5, 295 ],
            width: 443,
          )

          render_return_address(10, 278, 260, 70, size: 8)
          render_destination_address(165, 140, 230, 71, size: 14, valign: :bottom, align: :left)

          render_imb(240, 24, 183)
          render_qr_code(5, 115, 50)
          render_letter_id(10, 65, 10, rotate: 90)
          render_postage

          render_preview_bounds if preview_mode?
        end

        private

        def render_preview_bounds
          stroke_preview_bounds(10, 278, 260, 70, label: "return address")
          stroke_preview_bounds(165, 140, 230, 71, label: "destination address")
          stroke_preview_bounds(240, 24, 183, 12, label: "IMb barcode")
          stroke_preview_bounds(5, 115, 50, 50, label: "QR code")
          stroke_preview_bounds(10, 65, 10, 60, label: "letter ID")
          stroke_preview_bounds(bounds.right - 200, bounds.top, 200, 50, label: "postage + FIM-D")
        end

      end
    end
  end
end
