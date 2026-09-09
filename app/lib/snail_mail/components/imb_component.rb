module SnailMail
  module Components
    class IMbComponent < BaseComponent
      def initialize(letter:, x:, y:, width:, **options)
        @x = x
        @y = y
        @width = width
        super(letter: letter, **options)
      end

      def view_template
        # Only render IMB for appropriate US mail scenarios
        return unless letter.address.us? || letter.return_address.us?

        default_options = {
          font: "imb",
          size: 24,
          align: :center,
          overflow: :shrink_to_fit
        }

        opts = default_options.merge(options)
        font_name = opts.delete(:font)

        font(font_name) do
          text_box(
            generate_imb(letter),
            at: [ @x, @y ],
            width: @width,
            disable_wrap_by_char: true,
            **opts,
          )
        end

        stroke_preview_bounds(@x, @y, @width, 24, label: "IMb barcode")
      end

      private

      def generate_imb(letter)
        IMb.new(letter).generate
      end
    end
  end
end
