# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class HackatimeOTPTemplate < HalfLetterComponent
        ADDRESS_FONT = "comic"

        def self.template_name
          "hackatime OTP"
        end

        def self.template_size
          :half_letter
        end

        def render_front
          move_down 100
          text("Your Hackatime sign-in code is:", style: :bold, size: 30, align: :center)
          move_down 10
          text(letter.rubber_stamps || "mrrrrp :3", style: :bold, size: 80, align: :center)
          text("This code will expire in 1 year.", size: 10, align: :center)
          text("(that's #{1.year.from_now.in_time_zone("America/New_York").strftime("%-I:%M %p EST on %B %d")})", size: 9, align: :center, style: :italic)

          stroke_rectangle([ 2, 55 ], bounds.width - 5, 52)

          bounding_box([ 5, 50 ], width: bounds.width - 15, height: 49) do
            self.line_width = 3
            text("CONFIDENTIALITY NOTICE:", style: :bold, size: 8)
            text("The information contained in this letter is intended only for the use of the individual named on the address side. It may contain information that is privileged, confidential, and exempt from disclosure under applicable law. If you are not the intended recipient, you are hereby notified that any disclosure, copying, or distribution of this information is prohibited. If you believe you have received this letter in error, please notify us immediately by return postcard and securely destroy the original letter.", size: 8)
          end
        end
      end
    end
  end
end
