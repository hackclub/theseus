module SnailMail
  module Components
    module Templates
      class MailOrpheusTemplate < TemplateBase
        def self.template_name = "Mail Orpheus!"

        def self.show_on_single? = true

        def view_template
          image(
            image_path("eleeza-mail-orpheus.png"),
            at: [ 320, 113 ],
            width: 106.4,
          )

          # Render speech bubble
          # image(
          #   image_path(speech_bubble_image),
          #   at: [speech_position[:x], speech_position[:y]],
          #   width: speech_position[:width]
          # )

          # Render return address
          render_return_address(10, 270, 130, 70)

          if letter.rubber_stamps.present?
            font("arial") do
              text_box(
                letter.rubber_stamps,
                at: [ 7, 55 ],
                width: 250,
                height: 50,
                overflow: :shrink_to_fit,
                disable_wrap_by_char: true,
                min_size: 1,
                size: 10
              )
            end
          end


          # Render destination address in speech bubble
          render_destination_address(
            79.5,
            202,
            237,
            100,
            size: 16, valign: :bottom, align: :left
          )

          # Render IMb barcode
          render_imb(78, 102, 237)

          # Render QR code for tracking
          render_qr_code(7, 67, 60)
          render_postage
        end
      end
    end
  end
end
