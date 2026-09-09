# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class MacondoTemplate < TemplateBase
        def self.template_name
          "macondo"
        end

        def self.template_description
          "Macondo"
        end

        def self.show_on_single?
          true
        end

        def view_template
          # MACONDO header banner (watercolor stripes + straw hat + hibiscus)
          image(
            image_path("macondo/title.png"),
            at: [ 0, 248 ],
            width: 432,
          )

          # decorative illustrations (3000x3000 squares with transparent padding)
          image(image_path("macondo/flower.png"), at: [ 20, 96 ], width: 80)    # hibiscus, lower-left
          image(image_path("macondo/flower.png"), at: [ 360, 158 ], width: 54)  # small hibiscus, beside address box
          image(image_path("macondo/capy.png"), at: [ 104, 87 ], width: 92)     # angry capy, bottom edge, left
          image(image_path("macondo/orpheus.png"), at: [ 300, 128 ], width: 120) # dino + watermelon, bottom-right

          # postal elements (reuse base helpers)
          render_return_address(10, 280, 160, 70, size: 8)
          render_postage

          render_destination_address(
            108, 172, 214, 72,
            size: 12, valign: :center, align: :left
          )

          render_qr_code(8, 168, 50)
          render_letter_id(8, 14, 8)
          render_imb(240, 24, 185)

          render_preview_bounds if preview_mode?
        end

        private

        def render_preview_bounds
          stroke_preview_bounds(10, 280, 160, 70, label: "return address")
          stroke_preview_bounds(108, 172, 214, 72, label: "destination address")
          stroke_preview_bounds(8, 168, 50, 50, label: "QR code")
          stroke_preview_bounds(240, 24, 185, 12, label: "IMb barcode")
          stroke_preview_bounds(8, 14, 60, 10, label: "letter ID")
          stroke_preview_bounds(bounds.right - 55, bounds.top - 5, 50, 50, label: "postage")
        end
      end
    end
  end
end
