module SnailMail
  module Templates
    class HCBStickersTemplate < BaseTemplate
      def self.template_name
        "HCB Stickers"
      end

      def render(pdf, letter)
        pdf.image(
          image_path("lilia-hcb-stickers-bg.png"),
          at: [0, 288],
          width: 432,
        )

        # Render speech bubble
        # pdf.image(
        #   image_path(speech_bubble_image),
        #   at: [speech_position[:x], speech_position[:y]],
        #   width: speech_position[:width]
        # )

        # Render return address
        render_return_address(pdf, letter, 10, 278, 146, 70)

        # Render destination address in speech bubble
        render_destination_address(
          pdf,
          letter,
          192,
          149,
          226,
          57,
          { size: 16, valign: :bottom, align: :left }
        )

        # Render IMb barcode
        render_imb(pdf, letter, 216, 25, 207)

        render_letter_id(pdf, letter, 10, 12, 10)
        render_qr_code(pdf, letter, 5, 196, 50)

        render_postage(pdf, letter)
      end
    end
  end
end
