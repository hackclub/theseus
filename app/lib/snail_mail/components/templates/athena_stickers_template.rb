# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class AthenaStickersTemplate < TemplateBase
        def self.template_name
          "Athena stickers"
        end

        def self.show_on_single?
          true
        end

        def view_template
          render_return_address(5, bounds.top - 45, 190, 90, size: 8, font: "f25")

          image(
            image_path("athena/logo-stars.png"),
            at: [ 5, bounds.top - 5 ],
            width: 80,
          )

          render_destination_address(
            104,
            196,
            256,
            107,
            size: 18, valign: :center, align: :left
          )

          render_speech_bubble(
            bubble_position: [ 72, 202 ],
            bubble_width: 306,
            bubble_height: 122,
            bubble_radius: 10,
            tail_x: 96,
            tail_y: 83,
            tail_width: 32.2,
            line_width: 2.5
          )

          image(
            image_path("athena/nyc-orphy.png"),
            at: [ 13, 98 ],
            height: 97,
          )

          render_imb(230, 25, 190)
          render_letter_id(3, 15, 8, rotate: 90)
          render_qr_code(7, 160, 50)
          render_postage
        end
      end
    end
  end
end
