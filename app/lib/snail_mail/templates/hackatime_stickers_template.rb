module SnailMail
  module Templates
    class HackatimeStickersTemplate < KestrelHeidiTemplate
      MSG = <<~EOT
        you're getting this because you coded for
        ≥15 minutes during Scrapyard and tracked
        it w/ Hackatime V2! ^_^

        zach sent you an email about it...
      EOT

      def self.template_name
        "Hackatime Stickers"
      end

      def render(pdf, letter)
        super
        render_letter_id(pdf, letter, 360, 13, 12)
        pdf.image(image_path("hackatime/badge.png"), at: [ 10, 92 ], width: 117)
        pdf.font("gohu") do
          pdf.text_box(MSG, at: [ 162, 278 ], size: 8)
        end
      end
    end
  end
end
