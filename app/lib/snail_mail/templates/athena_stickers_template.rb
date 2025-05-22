module SnailMail
  module Templates
    class AthenaStickersTemplate < BaseTemplate
      def self.template_name
        "Athena stickers"
      end

      def self.show_on_single?
        true
      end

      def render(pdf, letter)
        render_return_address(pdf, letter, 5, pdf.bounds.top - 45, 190, 90, size: 8, font: "f25")
        pdf.image(
          image_path("athena/logo-stars.png"),
          at: [5, pdf.bounds.top - 5],
          width: 80,
        )
        render_destination_address(
          pdf,
          letter,
          104,
          196,
          256,
          107,
          { size: 18, valign: :center, align: :left }
        )

        pdf.stroke do
          pdf.line_width = 2.5
          pdf.rounded_rectangle([72, 202], 306, 122, 10)
        end

        pdf.image(
          image_path("athena/nyc-orphy.png"),
          at: [13, 98],
          height: 97,
        )

        pdf.image(
          image_path("speech-tail.png"),
          at: [96, 83],
          width: 32.2,
        )

        render_imb(pdf, letter, 230, 25, 190)
        render_letter_id(pdf, letter, 3, 15, 8, rotate: 90)
        render_qr_code(pdf, letter, 7, 160, 50)
        render_postage(pdf, letter)
      end
    end
  end
end
