# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class SoMMagicHappening < HalfLetterComponent
        IMAGES = %w[wizard.png hotdogcat.jpg magic_smoke.png]

        def self.abstract? = false

        def address_font = "gohu"

        def self.template_name = "SoM Magic Happening"

        def self.template_size = :half_letter

        def self.show_on_single? = false

        def render_front
          image(
            image_path(IMAGES.sample),
            at: [ 410, bounds.bottom + 200 ],
            valign: :top,
            width: 150
          )

          meta = letter.metadata || {}
          project = (proj = meta["project"]).present? ? "#{proj} " : nil
          reviewer = meta["reviewer"].presence || "your secret admirer"
          text = <<~EOM
            Dearest #{letter.address&.first_name&.titleize},

            We wanted to send out a little personal thank you, just to say that your project #{project}really struck a chord with us at HQ.

            We love to see real creativity and people building with passion, and we think you're doing an amazing job!

            Many thanks & keep hacking!

            <3 ~#{reviewer}





            tl;dr: TS cool!
          EOM

          font "gohu" do text_box text, at: [ 15, bounds.top-15 ], width: bounds.right - 200 - 20, size: 14 end
        end

        def render_back
          super
        end
      end
    end
  end
end
