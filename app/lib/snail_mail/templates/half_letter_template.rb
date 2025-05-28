# frozen_string_literal: true
module SnailMail
  module Templates
    class HalfLetterTemplate < BaseTemplate
      ADDRESS_FONT = "f25"

      def self.template_name
        raise NotImplementedError, "Subclass must implement template_name"
      end

      def self.template_size
        :half_letter
      end

      def render_front(pdf, letter)
        raise NotImplementedError, "Subclass must implement render_front"
      end

      def render(pdf, letter)
        render_front(pdf, letter)

        pdf.start_new_page

        render_postage(pdf, letter)

        render_return_address(pdf, letter, 10, pdf.bounds.top - 10, 146, 70)
        render_imb(pdf, letter, pdf.bounds.right - 200, pdf.bounds.bottom + 17, 180)

        render_destination_address(
          pdf,
          letter,
          150,
          pdf.bounds.bottom + 210,
          300,
          100,
          { size: 23, valign: :bottom, align: :left, font: self.class::ADDRESS_FONT }
        )
      end
    end
  end
end
