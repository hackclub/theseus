module SnailMail
  module Templates
    class HCBWelcomePostcardTemplate < HalfLetterTemplate
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

      def render_front(pdf, letter)
        pdf.bounding_box([10, pdf.bounds.top - 10], width: pdf.bounds.width - 20, height: pdf.bounds.height - 20) do
          pdf.image(image_path("hcb/hcb-icon.png"), width: 60)
          pdf.text_box("Welcome to HCB!", size: 30, at: [70, pdf.bounds.top - 18])
        end

        pdf.bounding_box([20, pdf.bounds.top - 90], width: pdf.bounds.width - 40, height: pdf.bounds.height - 100) do
          pdf.text(letter.rubber_stamps || "", size: 15, align: :justify, overflow: :shrink_to_fit)
        end
      end
    end
  end
end
