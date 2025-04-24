module SnailMail
  module Templates
    class HcpcxcTemplate < BaseTemplate
      def self.template_name
        "hcpcxc"
      end


      def render(pdf, letter)
        pdf.image(
          image_path("dino-waving.png"),
          at: [ 333, letter.address.us? ? 163 : 140 ],
          width: 87
        )

        pdf.image(
          image_path("hcpcxc_ra.png"),
          at: [ 5, 288-5 ],
          width: 175
        )

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
