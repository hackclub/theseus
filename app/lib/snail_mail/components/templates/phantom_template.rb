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
          image(image_path("phantom/phantom_mail_label.png"), at: [ 0, 288 ], width: 432)

          render_return_address(10, 281, 210, 38, size: 10, min_font_size: 5)

          if letter.rubber_stamps.present?
            font("arial") do
              text_box(
                letter.rubber_stamps,
                at: [ 8, 154 ],
                width: 54,
                height: 72,
                size: 8,
                overflow: :shrink_to_fit,
                min_font_size: 1
              )
            end
          end

          render_destination_address(
            100, 204, 212, 114,
            size: 14, valign: :center, align: :left
          )

          render_imb(100, 86, 210)

          render_qr_code(8, 210, 50)

          render_letter_id(10, 19, 10, include_qr_code: false)

          render_postage
        end
      end
    end
  end
end
