module SnailMail
  module Components
    class PostageComponent < BaseComponent
      def initialize(letter:, x: nil, **options)
        @x = x
        super(letter: letter, **options)
      end

      def view_template
        x_position = @x || (bounds.right - 138)

        if letter.postage_type == "indicia"
          IMI.render_indicium(self, letter, letter.usps_indicium, x_position)
          FIM.render_fim_d(self, x_position - 62)
          stroke_preview_bounds(x_position - 62, bounds.top, 200, 50, label: "postage + FIM-D")
        elsif letter.postage_type == "stamps"
          render_stamps_postage(x_position)
          stroke_preview_bounds(bounds.right - 55, bounds.top - 5, 50, 50, label: "postage (stamps)")
        else
          render_generic_postage
          stroke_preview_bounds(bounds.right - 55, bounds.top - 5, 52, 50, label: "postage")
        end
      end

      private

      def render_stamps_postage(x_position)
        postage_amount = letter.postage
        stamps = USPS::McNuggetEngine.find_stamp_combination(postage_amount, stamps: options[:stamps])

        requested_stamps = format_stamps_text(stamps)
        postage_info = "i take #{ActiveSupport::NumberHelper.number_to_currency(postage_amount)} in postage, so #{requested_stamps}"

        bounding_box([ bounds.right - 55, bounds.top - 5 ], width: 50, height: 50) do
          font("f25") do
            text_box(
              postage_info,
              at: [ 1, 48 ],
              width: 48,
              height: 45,
              size: 8,
              align: :center,
              min_font_size: 4,
              overflow: :shrink_to_fit,
            )
          end
        end
      end

      def render_generic_postage
        bounding_box([ bounds.right - 55, bounds.top - 5 ], width: 52, height: 50) do
          font("f25") do
            text_box(
              "please affix however much postage your post would like",
              at: [ 1, 48 ],
              width: 50,
              height: 45,
              size: 8,
              align: :center,
              min_font_size: 4,
              overflow: :shrink_to_fit
            )
          end
        end
      end

      def format_stamps_text(stamps)
        if stamps.size == 1
          stamp = stamps.first
          "#{stamp[:count]} #{stamp[:name]}"
        elsif stamps.size == 2
          "#{stamps[0][:count]} #{stamps[0][:name]} and #{stamps[1][:count]} #{stamps[1][:name]}"
        else
          stamps.map.with_index do |stamp, index|
            if index == stamps.size - 1
              "and #{stamp[:count]} #{stamp[:name]}"
            else
              "#{stamp[:count]} #{stamp[:name]}"
            end
          end.join(", ")
        end
      end
    end
  end
end
