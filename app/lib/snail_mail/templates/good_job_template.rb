# frozen_string_literal: true
module SnailMail
  module Templates
    class GoodJobTemplate < BaseTemplate
      def self.template_name
        "good job"
      end

      def self.template_size
        :half_letter
      end

      def render(pdf, letter)
        pdf.font "arial" do
          pdf.text_box "good job", size: 99, at: [0, pdf.bounds.top], valign: :center, align: :center
        end

        pdf.text_box "from: @#{letter.metadata["gj_from"]}\n#{letter.metadata["gj_reason"]}", size: 18, at: [100, 100], align: :left
        pdf.start_new_page

        render_postage(pdf, letter)

        render_return_address(pdf, letter, 10, pdf.bounds.top - 10, 146, 70, font: "arial")
        render_imb(pdf, letter, pdf.bounds.right - 222, pdf.bounds.bottom + 25, 207)

        render_destination_address(
          pdf,
          letter,
          150,
          pdf.bounds.bottom + 210,
          237,
          100,
          { size: 20, valign: :bottom, align: :left, font: "arial" }
        )
      end
    end
  end
end
