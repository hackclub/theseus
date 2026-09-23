
module SnailMail
  module Components
    module Templates
      class CacTemplate < TemplateBase
        def self.template_name
          "Congressional App Challenge"
        end

        def self.template_description
          "orpheus on an eagle + #HouseOfCode (mono), indicia slot, one-line rubber stamp under return address"
        end

        def self.show_on_single?
          true
        end

        def view_template
          render_return_address(10, 278, 153, 48, size: 8)

          if letter.rubber_stamps.present?
            font("arial") do
              text_box(
                letter.rubber_stamps,
                at: [ 10, 230 ],
                width: 153,
                height: 12,
                size: 9,
                overflow: :shrink_to_fit,
                disable_wrap_by_char: true,
                min_font_size: 4,
              )
            end
          end

          image(
            image_path("cac/orpheus_eagle.png"),
            at: [ 7, 224 ],
            width: 160,
          )
          image(
            image_path("cac/house_of_code.png"),
            at: [ 10, 66 ],
            width: 155,
          )

          render_destination_address(190, 208, 236, 121, size: 18, valign: :bottom, align: :left)

          render_imb(240, 24, 183)
          render_qr_code(170, 56, 46, caption: false)
          render_letter_id(172, 20, 7)
          render_indicia_backdrop
          render_postage

          render_preview_bounds if preview_mode?
        end

        private

        def render_indicia_backdrop
          return unless letter.postage_type == "indicia"

          save_graphics_state do
            fill_color "FFFFFF"
            fill_rectangle [ bounds.right - 205, bounds.top ], 205, 52
          end
        end

        def render_preview_bounds
          stroke_preview_bounds(10, 230, 153, 12, label: "rubber stamps")
          stroke_preview_bounds(240, 24, 183, 12, label: "IMb barcode")
          stroke_preview_bounds(bounds.right - 200, bounds.top, 200, 50, label: "postage + FIM-D")
        end
      end
    end
  end
end
