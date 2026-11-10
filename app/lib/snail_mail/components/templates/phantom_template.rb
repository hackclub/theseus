# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class PhantomTemplate < TemplateBase
        def self.template_name
          "PHANTOM"
        end
        def self.show_on_single?
          true
        end

        def view_template
          image(image_path("phantom/phantom_mail_label.png"), at: [0, 288], width: 432)
          
          render_return_address(10, 278, 200, 60, size: 10)

          render_destination_address(
            105, 200, 250, 80,
            size: 13, valign: :center, align: :left
          )

          render_imb(105, 130, 200)
          
          render_qr_code(5, 200, 45)

          bounding_box [ 8, 142 ],
                        width: 56,
                        height: 67,
                        valign: :bottom do
            font_size 8
            text letter.rubber_stamps || ""
          end

          render_letter_id(10, 19, 10)
          
          render_postage
        end
      end
    end
  end
end
