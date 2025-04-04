module SnailMail
  module Templates
    class KestrelHeidiTemplate < BaseTemplate
      def self.template_name
        "kestrel's heidi template!"
      end


      def render(pdf, letter)
        pdf.image(
          image_path("kestrel-mail-heidi.png"),
          at: [ 107, 216 ],
          width: 305
        )

        render_return_address(pdf, letter, 10, 278, 190, 90, size: 14)

        render_destination_address(
          pdf,
          letter,
          126,
          201,
          266,
          letter.address.us? ? 67 : 90,
          { size: 16, valign: :center, align: :left }
        )

        render_imb(pdf, letter, 124, 128, 266)

        render_qr_code(pdf, letter, 7, 72+7, 72)
      end
    end
  end
end
