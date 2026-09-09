# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class HackatimeTemplate < TemplateBase
        def self.template_name
          "Hackatime (new)"
        end

        def view_template
          image(
            image_path("hackatime/its_about_time.png"),
            at: [ 13, 219 ],
            width: 409,
          )

          # Render return address
          render_return_address(10, 278, 146, 70, font: "f25")

          # Render destination address in speech bubble
          render_destination_address(
            80,
            134,
            290,
            86,
            size: 19, valign: :top, align: :left
          )

          # Render IMb barcode
          render_imb(216, 25, 207)

          render_letter_id(10, 19, 10)
          render_qr_code(5, 55, 50)

          render_postage
        end
      end
    end
  end
end
