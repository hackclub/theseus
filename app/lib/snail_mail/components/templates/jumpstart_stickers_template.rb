# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class JumpstartStickersTemplate < TemplateBase
        def self.template_name
          "jumpstart Zorp"
        end

        def self.template_description
          "awawawawa"
        end

        def self.show_on_single? = true


        def view_template
          image(
            image_path("kestrel-mail-heidi.png"),
            at: [ 107, 216 ],
            width: 305,
          )

          # Render return address
          render_return_address(10, 278, 260, 70, size: 10)
          render_destination_address(
            126,
            180,
            266,
            67,
            size: 16,
            valign: :bottom,
            align: :left
          )



          # Render postal elements
          render_imb(124, 180-67-5, 200)
          render_qr_code(5, 65, 60)
          render_letter_id(10, 19, 10)

          bounding_box [ 10, 220 ],
                        width: 220,
                        height: 120,
                        valign: :bottom do
            font_size 8
            font_size(10) { font("comic") { text "it's here!" } }
            text "contents:", style: :bold
            text letter.rubber_stamps || ""
          end

          render_postage
        end
      end
    end
  end
end
