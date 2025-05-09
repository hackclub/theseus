module SnailMail
  module Templates
    class HcpcxcTemplate < BaseTemplate
      def self.template_name
        "hcpcxc"
      end


      def render(pdf, letter)
        pdf.image(
          image_path("dino-waving.png"),
          at: [ 333, 163 ],
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

        render_qr_code(pdf, letter, 5, 65, 60)

        render_letter_id(pdf, letter, 10, 19, 10)
        if letter.rubber_stamps.present?
          pdf.font("arial") do
            pdf.text_box(
              letter.rubber_stamps,
              at: [ 294, 220 ],
              width: 255,
              height: 21,
              overflow: :shrink_to_fit,
              disable_wrap_by_char: true,
              min_size: 1
            )
          end
        end
        render_postage(pdf, letter)
      end
    end
  end
end
