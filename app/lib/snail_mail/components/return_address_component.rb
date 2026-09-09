module SnailMail
  module Components
    class ReturnAddressComponent < BaseComponent
      def initialize(letter:, x:, y:, width:, height:, **options)
        @x = x
        @y = y
        @width = width
        @height = height
        super(letter: letter, **options)
      end

      def view_template
        default_options = {
          font: "arial",
          size: 11,
          align: :left,
          valign: :top,
          overflow: :shrink_to_fit,
          min_font_size: 6
        }

        opts = default_options.merge(options)
        font_name = opts.delete(:font)

        font(font_name) do
          text_box(
            format_return_address(letter, opts[:no_name_line]),
            at: [ @x, @y ],
            width: @width,
            height: @height,
            **opts,
          )
        end

        stroke_preview_bounds(@x, @y, @width, @height, label: "return address")
      end

      private

      def format_return_address(letter, no_name_line = false)
        return_address = letter.return_address
        return "No return address" unless return_address

        <<~EOA
          #{letter.return_address_name_line unless no_name_line}
          #{[ return_address.line_1, return_address.line_2 ].compact_blank.join("\n")}
          #{return_address.city}, #{return_address.state} #{return_address.postal_code}
          #{return_address.country if return_address.country != letter.address.country}
        EOA
          .strip
      end
    end
  end
end
