# frozen_string_literal: true

module SnailMail
  module Components
    module Templates
      class Hackatime7DayStreakTemplate < HalfLetterComponent
        def self.abstract? = false

        def address_font = "times"

        def self.template_name
          "Hackatime 7 Day Streak"
        end

        def self.template_size
          :half_letter
        end


        def render_front
          image(
            image_path("hackatime/7_day_streak.png"),
            at: [ 10, bounds.top - 10 ],
            height: bounds.top - 20,
          )

          ca = letter.metadata.dig("attributes", "created_at")
          ca = Date.parse(ca) rescue nil if ca.present?

          text = <<~EOM
            Dearest #{letter.address&.first_name&.upcase} #{letter.address&.last_name&.[](0)&.upcase}.,

            #{ca.present? ? "On the #{ca.day.ordinalize} of #{Date::MONTHNAMES[ca.month]}" : "Recently"} you joined the ranks of those who have logged coding time on Hackatime 7 days in a row.

            In recognition of your achievement, we'd like to present you with this postcard.

            It is yours. You have earned it.

            Thank you for making your hours count.
            We've enjoyed counting your hours.

            Best of luck to you in all your future endeavors.

            We'll be watching.

            Warmly,
            the Hackatime Advisory Council
          EOM

          font "times" do text_box text, at: [ 280, bounds.top-15 ], width: bounds.right - 280 - 20 end
        end

        def render_back
          super
          image(
            image_path("hackatime/this_is_fine.png"),
            at: [ 75, 130 ],
            height: 140
          )
        end
      end
    end
  end
end
