# frozen_string_literal: true
module SnailMail
  module Templates
    class GoodJobTemplate < HalfLetterTemplate
      ADDRESS_FONT = "arial"
      def self.template_name
        "good job"
      end

      def self.template_size
        :half_letter
      end

      def render_front(pdf, letter)
        pdf.font "arial" do
          pdf.text_box "good job", size: 99, at: [0, pdf.bounds.top], valign: :center, align: :center
        end

        pdf.text_box "from: @#{letter.metadata["gj_from"]}\n#{letter.metadata["gj_reason"]}", size: 18, at: [100, 100], align: :left
      end
    end
  end
end
