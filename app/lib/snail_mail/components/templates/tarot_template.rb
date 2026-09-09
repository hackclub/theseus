# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class TarotTemplate < TemplateBase
        def self.template_name
          "Tarot"
        end

        def view_template
          render_return_address(10, 278, 190, 90, size: 12, font: "comic")

          if letter.rubber_stamps.present?
            font("gohu") do
              text_box(
                "\"#{letter.rubber_stamps}\"",
                at: [ 137, 183 ],
                width: 255,
                height: 21,
                overflow: :shrink_to_fit,
                disable_wrap_by_char: true,
                min_size: 1
              )
            end
          end

          render_destination_address(
            137,
            160,
            255,
            90,
            size: 16, valign: :center, align: :left
          )

          stroke do
            self.line_width = 1
            line([ 137 - 25, 167 ], [ 392 + 25, 167 ])
          end

          render_speech_bubble(
            bubble_position: [ 111, 189 ],
            bubble_width: 306,
            bubble_height: 122,
            bubble_radius: 10,
            tail_x: 118,
            tail_y: 70,
            tail_width: 32.2,
            line_width: 2.5
          )

          image(
            image_path("tarot/msw-joker.png"),
            at: [ 6, 104 ],
            width: 111
          )

          render_imb(216, 25, 207)
          render_letter_id(3, 15, 8, rotate: 90)
          render_qr_code(7, 72 + 7, 72)
          render_postage
        end
      end
    end
  end
end
