module SnailMail
  module Templates
    class DinoWavingTemplate < BaseTemplate
      def self.template_name
        "Dino Waving"
      end


      def render(pdf, letter)
        pdf.image(
          image_path("dino-waving.png"),
          at: [ 333, letter.address.us? ? 163 : 140 ],
          width: 87
        )

        # Render return address
        render_return_address(pdf, letter, 10, 278, 260, 70, size: 10)

        # Render destination address in speech bubble
        render_destination_address(
          pdf,
          letter,
          88,
          166,
          236,
          71,
          { size: 16, valign: :bottom, align: :left }
        )

        # Render IMb barcode
        render_imb(pdf, letter, 240, 24, 183)

        render_letter_id(pdf, letter, 10, 19, 10)
        render_postage(pdf, letter)
      end
    end
  end
end
