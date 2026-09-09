# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class HcpcxcTemplate < TemplateBase
        def self.template_name
          "hcpcxc"
        end

        def view_template
          image(
            image_path("dino-waving.png"),
            at: [ 333, 163 ],
            width: 87
          )

          image(
            image_path("hcpcxc_ra.png"),
            at: [ 5, 288-5 ],
            width: 175
          )

          render_destination_address(
            88,
            166,
            236,
            71,
            size: 16, valign: :bottom, align: :left
          )

          # Render IMb barcode
          render_imb(240, 24, 183)

          render_qr_code(5, 65, 60)

          render_letter_id(10, 19, 10)

          if letter.rubber_stamps.present?
            font("arial") do
              text_box(
                letter.rubber_stamps,
                at: [ 294, 220 ],
                width: 255,
                height: 21,
                overflow: :shrink_to_fit,
                disable_wrap_by_char: true,
                min_size: 1
              )
            end
          end

          render_postage
        end
      end
    end
  end
end
