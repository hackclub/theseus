module SnailMail
  module Components
    module Templates
      class JoyousCatTemplate < TemplateBase
      def self.template_name = "Joyous Cat :3"

      def self.show_on_single? = true

      def view_template
        self.line_width = 3
        stroke { rounded_rectangle([ 111, 189 ], 306, 122, 10) }


        image(
          image_path("acon-joyous-cat.png"),
          at: [ 208, 74 ],
          width: 106.4,
        )

        render_return_address(10, 270, 130, 70)

        if letter.rubber_stamps.present?
          font("arial") do
            text_box(
              letter.rubber_stamps,
              at: [ 10, 50 ],
              width: 180,
              height: 18,
              overflow: :shrink_to_fit,
              disable_wrap_by_char: true,
              min_size: 1
            )
          end
        end

        render_destination_address(
          134,
          173,
          266,
          67,
          size: 16,
          valign: :center,
          align: :left
        )

        render_imb(131, 100, 266)
        render_qr_code(7, 72 + 7, 72)
        render_postage
      end
      end
    end
  end
end
