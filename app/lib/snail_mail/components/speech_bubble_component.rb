module SnailMail
  module Components
    class SpeechBubbleComponent < BaseComponent
      def initialize(letter:, bubble_position:, bubble_width:, bubble_height:, bubble_radius: 10, tail_x:, tail_y:, tail_width:, line_width: 2.5, **options)
        @bubble_position = bubble_position
        @bubble_width = bubble_width
        @bubble_height = bubble_height
        @bubble_radius = bubble_radius
        @tail_x = tail_x
        @tail_y = tail_y
        @tail_width = tail_width
        @line_width = line_width
        super(letter: letter, **options)
      end

      def view_template
        # Draw the rounded rectangle bubble
        self.line_width = @line_width
        stroke do
          rounded_rectangle(@bubble_position, @bubble_width, @bubble_height, @bubble_radius)
        end

        # Draw the speech tail
        image(
          image_path("speech-tail.png"),
          at: [ @tail_x, @tail_y ],
          width: @tail_width
        )
      end
    end
  end
end
