require_relative "../base_template"

module SnailMail
  module Templates
    class CharacterTemplate < BaseTemplate
      # Abstract base class for character templates

      def self.template_name
        "character" # This template isn't meant to be used directly
      end

      def self.template_description
        "Base class for character templates (not for direct use)"
      end

      attr_reader :character_image, :speech_bubble_image, :character_position, :speech_position

      def initialize(options = {})
        super
        @character_image = options[:character_image]
        @speech_bubble_image = options[:speech_bubble_image] || "speech_bubble.png"
        @character_position = options[:character_position] || { x: 10, y: 100, width: 120 }
        @speech_position = options[:speech_position] || { x: 100, y: 250, width: 300, height: 100 }
      end

      def render(pdf, letter)
        # Render character
        pdf.image(
          image_path(character_image),
          at: [ character_position[:x], character_position[:y] ],
          width: character_position[:width]
        )

        # Render speech bubble
        pdf.image(
          image_path(speech_bubble_image),
          at: [ speech_position[:x], speech_position[:y] ],
          width: speech_position[:width]
        )

        # Render return address
        render_return_address(pdf, letter, 10, 270, 130, 70)

        # Render destination address in speech bubble
        render_destination_address(
          pdf,
          letter,
          speech_position[:x] + 20,
          speech_position[:y] - 10,
          speech_position[:width] - 40,
          speech_position[:height] - 20,
          { size: 12, valign: :center }
        )

        # Render IMb barcode
        render_imb(pdf, letter, 100, 90, 280, 30)

        # Render QR code for tracking
        render_qr_code(pdf, letter, 5, 65, 60)
        render_postage(pdf, letter)
      end
    end
  end
end
