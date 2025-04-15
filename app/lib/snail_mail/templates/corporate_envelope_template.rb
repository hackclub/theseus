require_relative "../base_template"

module SnailMail
  module Templates
    class CorporateEnvelopeTemplate < BaseTemplate
      def self.template_name
        "corporate_envelope"
      end

      def self.template_size
        :envelope # Use the envelope size from BaseTemplate::SIZES
      end

      def self.template_description
        "Professional business envelope template"
      end

      def render(pdf, letter)
        # Draw a subtle border
        pdf.stroke do
          pdf.rectangle [ 15, 4 * 72 - 15 ], 9.5 * 72 - 30, 4.125 * 72 - 30
        end

        # Render return address in top left
        pdf.font("Helvetica") do
          pdf.text_box(
            format_return_address(letter),
            at: [ 30, 4 * 72 - 30 ],
            width: 250,
            height: 60,
            overflow: :shrink_to_fit,
            min_font_size: 8,
            style: :bold
          )
        end

        # Render destination address
        pdf.font("Helvetica") do
          pdf.text_box(
            format_destination_address(letter),
            at: [ 4.5 * 72 - 200, 2.5 * 72 + 50 ],
            width: 400,
            height: 120,
            overflow: :shrink_to_fit,
            min_font_size: 10,
            leading: 2
          )
        end

        # Render IMb barcode at bottom
        render_imb(pdf, letter, 72, 30, 7 * 72, 30)

        # Render QR code in bottom left with smaller size
        render_qr_code(pdf, letter, 25, 70, 50)
        render_postage(pdf, letter)
      end
    end
  end
end
