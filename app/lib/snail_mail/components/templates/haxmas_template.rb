# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class HaxmasTemplate < TemplateBase
        def self.template_name
          "Haxmas"
        end

        def self.show_on_single?
          true
        end

        def view_template
          image(
            image_path("haxmas.png"),
            at: [ -2.5, 295 ],
            width: 443,
          )


          render_return_address(10, 278, 260, 70, size: 8, font: "f25")


          render_destination_address(
            100,
            200,
            260,
            120,
            size: 14,
            valign: :center,
            align: :left
          )

          bounding_box [ 7, 165 ],
                        width: 65,
                        height: 67,
                        valign: :bottom do
            font_size 8
            text letter.rubber_stamps || ""
          end


          render_imb(140, 70, 183)
          render_qr_code(310, 262, 42)
          render_letter_id(2, 5, 6)
          render_postage
        end
      end
    end
  end
end
