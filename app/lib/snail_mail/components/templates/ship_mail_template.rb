# frozen_string_literal: true
module SnailMail
  module Components
    module Templates
      class ShipMailTemplate < TemplateBase
        def self.template_name
          "Ship Mail"
        end
        def self.show_on_single?
          true
        end
        def view_template
          image(
            image_path("ship_mail.png"),
            at: [-2.5, 288],
            width: 443,
          )

          render_return_address(5, bounds.top - 5, 190, 90, size: 8, font: "f25")
          render_destination_address(85, bounds.top - 75, 260, 130, size: 18, valign: :center, align: :left)
          render_imb(245, 20, 170)
          render_qr_code(150, 260, 35)
          render_letter_id(3, 15, 8, rotate: 90)
          render_postage
        end
      end
    end
  end
end
