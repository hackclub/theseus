module SnailMail
  module Templates
    class HackatimeTemplate < BaseTemplate
      def self.template_name
        "Hackatime (new)"
      end

      def render(pdf, letter)
        pdf.image(
          image_path("hackatime/its_about_time.png"),
          at: [13, 219],
          width: 409,
        )

        # Render speech bubble
        # pdf.image(
        #   image_path(speech_bubble_image),
        #   at: [speech_position[:x], speech_position[:y]],
        #   width: speech_position[:width]
        # )

        # Render return address
        render_return_address(pdf, letter, 10, 278, 146, 70, font: "f25")

        # Render destination address in speech bubble
        render_destination_address(
          pdf,
          letter,
          80,
          134,
          290,
          86,
          { size: 19, valign: :top, align: :left }
        )

        # Render IMb barcode
        render_imb(pdf, letter, 216, 25, 207)

        render_letter_id(pdf, letter, 10, 19, 10)
        render_qr_code(pdf, letter, 5, 55, 50)

        render_postage(pdf, letter)
      end
    end
  end
end
