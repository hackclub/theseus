module SnailMail
  module Components
    module Templates
      class KestrelHeidiTemplate < TemplateBase
      def self.template_name = "kestrel's heidi template!"

      def self.show_on_single? = true

      def view_template
        image(
          image_path("kestrel-mail-heidi.png"),
          at: [ 107, 216 ],
          width: 305,
        )

        render_return_address(10, 278, 190, 90, size: 14)

        if letter.rubber_stamps.present?
          font("arial") do
            text_box(
              letter.rubber_stamps,
              at: [ 7, 80 ],
              width: 150,
              height: 80,
              overflow: :shrink_to_fit,
              disable_wrap_by_char: true,
              min_size: 1
            )
          end
        end

        render_destination_address(
          126,
          201,
          266,
          67,
          size: 16,
          valign: :center,
          align: :left
        )

        render_imb(124, 120, 200)
        render_qr_code(7, 72 + 7, 72)
        render_postage
      end
      end
    end
  end
end
