module SnailMail
  module Components
    class HalfLetterComponent < TemplateBase
      def address_font = "f25"

      def self.abstract?
        true
      end
      
      def self.template_size
        :half_letter
      end

      def view_template
        render_front
        start_new_page
        render_back
      end

      # Override in subclasses to define the front content
      def render_front
        raise NotImplementedError, "Subclasses must implement render_front"
      end

      def render_back
        render_postage
        render_imb(bounds.right - 217, 25, 207)
        render_return_address(15, bounds.top - 15, 190, 90, size: 8, font: address_font)
        render_destination_address(
          (bounds.right/2)-256/2,
          260,
          256,
          107,
          size: 18, valign: :center, align: :left, font: address_font
        )
        render_qr_code(15, 200, 65)
        font(address_font, size: 8) do
          text_box(letter.public_id, at: [15, bounds.top - 110], width: 100, overflow: :shrink_to_fit)
        end
      end
    end
  end
end
