# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class FtWellCooked < HalfLetterComponent
        IMAGES = %w[wizard.png hotdogcat.jpg magic_smoke.png]

        def self.abstract? = false

        def address_font = "gohu"

        def self.template_name = "Flavortown Well Cooked"

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
            Hey, Chef #{letter.address&.first_name&.titleize},

            We wanted to send our compliments to the chef, (that's you!), to say that your project #{project}really added some flavour to the menu at HQ!

            We love to see real creativity and people cooking with passion, and we think you're doing an amazing job in the kitchen!

            Many thanks & keep hacking!

            <3 Head Chef ~#{reviewer}





            tl;dr: TS well cooked!
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
