require_relative "../base_template"

module SnailMail
  module Templates
    class EnvelopeTemplate < BaseTemplate
      def self.template_name
        "envelope"
      end

      def self.template_size
        :envelope # Use the envelope size from BaseTemplate::SIZES
      end

      def self.template_description
        "Standard #10 business envelope template"
      end

      def render(pdf, letter)
        # Render return address in top left
        render_return_address(pdf, letter, 15, 4 * 72 - 30, 250, 60)

        # Render destination address centered
        render_destination_address(
          pdf,
          letter,
          4.5 * 72 - 150, # Centered horizontally
          2.5 * 72, # Centered vertically
          300,  # Width
          120,  # Height
          {
            size: 12,
            valign: :center,
            align: :center
          }
        )

        # Render IMb barcode at bottom
        render_imb(pdf, letter, 72, 30, 7 * 72, 30)

        # Render QR code in bottom left
        render_qr_code(pdf, letter, 15, 70, 60)
        render_postage(pdf, letter)
      end
    end
  end
end
