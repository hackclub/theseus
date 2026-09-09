# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class SummerOfMakingFreeStickersTemplate < TemplateBase
        def self.template_name
          "SoM Free Stickers"
        end

        def self.show_on_single?
          true
        end

        def view_template
          render_return_address(5, bounds.top - 5, 190, 90, size: 8, font: "f25")

          render_destination_address(
            120,
            115,
            270,
            81,
            size: 18, valign: :center, align: :left
          )

          image(
            image_path("som/banner.png"),
            at: [ -2.5, 288 - 56 ],
            width: 443,
          )

          render_imb(245, 20, 170)
          render_letter_id(3, 15, 8, rotate: 90)
          render_qr_code(2, 52, 50)
          render_postage
        end
      end
    end
  end
end
