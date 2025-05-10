# frozen_string_literal: true
module SnailMail
  module Templates
    class GoodJobTemplate < BaseTemplate
      def self.template_name
        "good job"
      end

      def render(pdf, letter)
        pdf.font "arial" do
          pdf.text_box "good job", size: 99, at: [0,288], valign: :center, align: :center
        end
        pdf.start_new_page

        render_postage(pdf, letter)

        render_return_address(pdf, letter, 10, 278, 146, 70, font: "arial")
        render_imb(pdf, letter, 216, 25, 207)

        render_destination_address(
          pdf,
          letter,
          100,
          170,
          237,
          100,
          { size: 20, valign: :bottom, align: :left, font: "arial" }
        )

      end
    end
  end
end