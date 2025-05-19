module SnailMail
  module Templates
    class HeidiReadmeTemplate < BaseTemplate
      def self.template_name
        "Heidi Can't Readme"
      end

      def self.show_on_single?
        true
      end

      def render(pdf, letter)
        render_return_address(pdf, letter, 10, 278, 190, 90, size: 12, font: "f25")

        render_destination_address(
          pdf,
          letter,
          133,
          176,
          256,
          107,
          { size: 18, valign: :center, align: :left }
        )

        pdf.stroke do
          pdf.line_width = 2.5
          pdf.rounded_rectangle([90 + 20, 189 - 5], 306, 122, 10)
        end

        pdf.image(
          image_path("msw-heidi-cant-readme.png"),
          at: [6 + 20, 75],
          width: 111,
        )

        pdf.image(
          image_path("speech-tail.png"),
          at: [114 + 20, 70 - 5],
          width: 32.2,
        )

        render_imb(pdf, letter, 230, 25, 190)
        render_letter_id(pdf, letter, 3, 15, 8, rotate: 90)
        render_qr_code(pdf, letter, 7, 72 + 7 + 50 + 10 + 12, 60)
        render_postage(pdf, letter)
      end
    end
  end
end
