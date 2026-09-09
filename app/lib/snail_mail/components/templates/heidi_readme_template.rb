# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class HeidiReadmeTemplate < TemplateBase
        def self.template_name = "Heidi Can't Readme"

        def self.show_on_single? = true

        def view_template
          render_return_address(10, 278, 190, 90, size: 12, font: "f25")

          if letter.rubber_stamps.present?
            font("arial") do
              text_box(
                letter.rubber_stamps,
                at: [ 10, 220 ],
                width: 256,
                height: 30,
                overflow: :shrink_to_fit,
                disable_wrap_by_char: true,
                min_size: 1,
                size: 10
              )
            end
          end

          render_destination_address(
            133,
            176,
            256,
            107,
            size: 18, valign: :center, align: :left
          )

          render_speech_bubble(
            bubble_position: [ 90 + 20, 189 - 5 ],
            bubble_width: 306,
            bubble_height: 122,
            bubble_radius: 10,
            tail_x: 114 + 20,
            tail_y: 70 - 5,
            tail_width: 32.2,
            line_width: 2.5
          )

          image(
            image_path("msw-heidi-cant-readme.png"),
            at: [ 6 + 20, 75 ],
            width: 111,
          )

          render_imb(230, 25, 190)
          render_letter_id(3, 15, 8, rotate: 90)
          render_qr_code(7, 72 + 7 + 50 + 10 + 12, 60)
          render_postage
        end
      end
    end
  end
end
