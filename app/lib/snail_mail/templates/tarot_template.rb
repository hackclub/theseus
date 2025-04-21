module SnailMail
  module Templates
    class TarotTemplate < BaseTemplate
      def self.template_name
        "Tarot"
      end

      def render(pdf, letter)
        render_return_address(pdf, letter, 10, 278, 190, 90, size: 12, font: 'comic')

        if letter.rubber_stamps.present?
          pdf.font("gohu") do
            pdf.text_box(
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
          pdf,
          letter,
          137,
          160,
          255,
          90,
          { size: 16, valign: :center, align: :left }
        )
        pdf.stroke do
          pdf.line_width = 1
          pdf.line([ 137 - 25, 167 ], [ 392 + 25, 167 ])
        end

        pdf.stroke do
          pdf.line_width = 2.5
          pdf.rounded_rectangle([ 111, 189 ], 306, 122, 10)
        end

        pdf.image(
          image_path("tarot/msw-joker.png"),
          at: [ 6, 104 ],
          width: 111
        )

        pdf.image(
          image_path("speech-tail.png"),
          at: [ 118, 70 ],
          width: 32.2
        )

        render_imb(pdf, letter, 216, 25, 207)
        render_letter_id(pdf, letter, 3, 15, 8, rotate: 90)
        render_qr_code(pdf, letter, 7, 72 + 7, 72)
        render_postage(pdf, letter)
      end
    end
  end
end
