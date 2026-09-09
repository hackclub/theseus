module SnailMail
  module Components
    class LetterIdComponent < BaseComponent
      def initialize(letter:, x:, y:, size:, **options)
        @x = x
        @y = y
        @size = size
        super(letter: letter, **options)
      end

      def view_template
        return if options[:include_qr_code]

        font(options[:font] || "f25") do
          text_box(
            letter.public_id,
            at: [ @x, @y ],
            size: @size,
            overflow: :shrink_to_fit,
            valign: :top,
            **options.except(:font)
          )
        end

        stroke_preview_bounds(@x, @y, 50, @size, label: "letter ID")
      end
    end
  end
end
