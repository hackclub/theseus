# frozen_string_literal: true

# this is shit mailpiece design
# usps will want to kill me
# but it's cute!


module SnailMail
  module Components
    module Templates
      class SummerOfMakingFulfillmentTemplate < TemplateBase
        def self.template_name
          "summer of making fulfillment"
        end

        def self.template_description
          "awawawawa"
        end

        def self.show_on_single? = true


        def view_template
          image(
            image_path("som/explorers.png"),
            at: [ 189-30, 115+30 ],
            width: 300,
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
          render_qr_code(5, 45, 40)
          render_letter_id(10, 19, 10)

            bounding_box [ 10, 235 ],
                         width: 100,
                         height: 168,
                         valign: :bottom do
              font_size 8
              font_size(7) { font("comic") { text "it's here!" } }
              text "contents:", style: :bold
              font_size 6.2
              text letter.rubber_stamps.gsub(", ", "\n") || ""
            end




          render_postage
        end
      end
    end
  end
end
