module SnailMail
  module Templates
    class MailOrpheusTemplate < BaseTemplate
      def self.template_name
        "Mail Orpheus!"
      end

      def self.show_on_single?
        true
      end

      def render(pdf, letter)
        pdf.image(
          image_path("eleeza-mail-orpheus.png"),
          at: [320, 113],
          width: 106.4,
        )

        # Render speech bubble
        # pdf.image(
        #   image_path(speech_bubble_image),
        #   at: [speech_position[:x], speech_position[:y]],
        #   width: speech_position[:width]
        # )

        # Render return address
        render_return_address(pdf, letter, 10, 270, 130, 70)

        # Render destination address in speech bubble
        render_destination_address(
          pdf,
          letter,
          79.5,
          202,
          237,
          100,
          { size: 16, valign: :bottom, align: :left }
        )

        # Render IMb barcode
        render_imb(pdf, letter, 78, 102, 237)

        # Render QR code for tracking
        render_qr_code(pdf, letter, 7, 67, 60)
        render_postage(pdf, letter)
      end
    end
  end
end
