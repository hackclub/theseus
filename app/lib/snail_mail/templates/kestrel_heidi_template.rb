module SnailMail
  module Templates
    class KestrelHeidiTemplate < BaseTemplate
      def self.template_name
        "kestrel's heidi template!"
      end

      def self.show_on_single?
        true
      end

      def render(pdf, letter)
        pdf.image(
          image_path("kestrel-mail-heidi.png"),
          at: [107, 216],
          width: 305,
        )

        render_return_address(pdf, letter, 10, 278, 190, 90, size: 14)

        render_destination_address(
          pdf,
          letter,
          126,
          201,
          266,
          67,
          { size: 16, valign: :center, align: :left }
        )

        render_imb(pdf, letter, 124, 120, 200)

        render_qr_code(pdf, letter, 7, 72 + 7, 72)

        render_postage(pdf, letter)
      end
    end
  end
end
