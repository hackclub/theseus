require_relative "character_template"

module SnailMail
  module Templates
    class OrpheusTemplate < CharacterTemplate
      def initialize(options = {})
        super(options.merge(
          character_image: "eleeza-mail-orpheus.png",
          character_position: { x: 10, y: 85, width: 130 },
          speech_position: { x: 95, y: 240, width: 290, height: 90 }
        ))
      end
    end
  end
end
