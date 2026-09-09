# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class CalculateTemplate < TemplateBase
        def self.template_name
          "calculate"
        end

        def self.template_description
          "Calculate"
        end

        def self.show_on_single?
          true
        end

        def view_template
          # full-bleed background design (2100x1500, ~1.4:1 aspect vs 432x288 canvas)
          image(image_path("calculate/main.png"), at: [0, 288], width: 432, height: 288)

          render_return_address(10, 280, 160, 70, size: 8)
          render_postage

          render_destination_address(
            108, 205, 214, 72,
            size: 12, valign: :center, align: :left
          )

          render_qr_code(8, 168, 50)
          render_letter_id(100, 50, 8)
          render_imb(240, 24, 185)

          render_preview_bounds if preview_mode?
        end

        private

        def render_preview_bounds
          stroke_preview_bounds(10, 280, 160, 70, label: "return address")
          stroke_preview_bounds(108, 220, 214, 72, label: "destination address")
          stroke_preview_bounds(8, 168, 50, 50, label: "QR code")
          stroke_preview_bounds(240, 24, 185, 12, label: "IMb barcode")
          stroke_preview_bounds(170, 14, 60, 10, label: "letter ID")
          stroke_preview_bounds(bounds.right - 55, bounds.top - 5, 50, 50, label: "postage")
        end
      end
    end
  end
end
