module SnailMail
  module Templates
    class JoyousCatTemplate < BaseTemplate
      def self.template_name
        "Joyous Cat :3"
      end

      def self.show_on_single?
        true
      end

      def render(pdf, letter)
        pdf.line_width = 3
        pdf.stroke do
          pdf.rounded_rectangle([111, 189], 306, 122, 10)
        end

        pdf.image(
          image_path("acon-joyous-cat.png"),
          at: [208, 74],
          width: 106.4,
        )

        render_return_address(pdf, letter, 10, 270, 130, 70)

        render_destination_address(
          pdf,
          letter,
          134,
          173,
          266,
          67,
          { size: 16, valign: :center, align: :left }
        )

        render_imb(pdf, letter, 131, 100, 266)

        render_qr_code(pdf, letter, 7, 72 + 7, 72)
        render_postage(pdf, letter)
      end
    end
  end
end
