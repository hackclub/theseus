# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class HCBWelcomePostcardTemplate < HalfLetterComponent
        def self.abstract?
          false
        end

        ADDRESS_FONT = "arial"

        def self.template_name
          "hcb welcome postcard"
        end

        SAMPLE_WELCOME_TEXT = "Hey!

        I'm super excited to work with your org because I think whatever you do is a really important cause and it aligns perfectly with our mission to support things that we believe are good.

        At HCB, we're all about empowering organizations like yours to make a real difference in the world. We believe in the power of community, innovation, and collaboration to create positive change. Your work resonates deeply with our values, and we can't wait to see the amazing things we'll accomplish together.

        We're here to support you every step of the way. Whether you need technical assistance, community resources, or just someone to bounce ideas off of, our team is ready to help. We're not just a service provider – we're your partner in making the world a better place.

        Let's build something incredible together!

        Warm regards,
        The HCB Team"

        def render_front
          bounding_box([ 10, bounds.top - 10 ], width: bounds.width - 20, height: bounds.height - 20) do
            image(image_path("hcb/hcb-icon.png"), width: 60)
            text_box("Welcome to HCB!", size: 30, at: [ 70, bounds.top - 18 ])
          end

          bounding_box([ 20, bounds.top - 90 ], width: bounds.width - 40, height: bounds.height - 100) do
            text(letter.rubber_stamps || "", size: 15, align: :justify, overflow: :shrink_to_fit)
          end
        end
      end
    end
  end
end
