# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class SdSuperStar < HalfLetterComponent
        IMAGE = "stardance/starlings.png"

        def self.abstract? = false

        def address_font = "gohu"

        def self.template_name = "Stardance Super Star"

        def self.template_size = :half_letter

        def self.show_on_single? = false

        def render_front
          image(
            image_path(IMAGE),
            at: [410, bounds.bottom + 200],
            valign: :top,
            width: 150
          )

          meta = letter.metadata || {}
          project = (proj = meta["project"]).present? ? "#{proj} " : nil
          reviewer = meta["reviewer"].presence || "your secret admirer"
          text = <<~EOM
            Hey, #{letter.address&.first_name&.titleize},

            We wanted to tell the star of the day, (that's you!), that your project #{project}really brightened up the sky at HQ!

            We love seeing people shoot for the stars, and you're shining brighter than ever!

            Many thanks & keep hacking!

            <3 ~#{reviewer} @ Hack Club HQ





            tl;dr: TS is out of this world!
          EOM

          font "gohu" do text_box text, at: [15, bounds.top-15], width: bounds.right - 200 - 20, size: 14 end

          if (listing_url = meta["listing_url"]).present?
            SnailMail::QRCodeGenerator.generate_qr_code(self, listing_url, 460, 75, 50)
            font("gohu", size: 7) do
              text_box("view project", at: [455, 20], width: 60, align: :center)
            end
          end
        end

        def render_back
          img_path = image_path("stardance/astronomical.png")
          img_info = Prawn::Images::PNG.new(File.binread(img_path))
          target_w = bounds.right + 5
          rendered_h = img_info.height * (target_w / img_info.width.to_f)
          image(img_path, at: [-2.5, rendered_h], width: target_w)
          super
        end
      end
    end
  end
end
