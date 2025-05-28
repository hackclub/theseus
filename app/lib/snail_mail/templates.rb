module SnailMail
  module Templates
    class TemplateNotFoundError < StandardError; end

    # All available templates hardcoded in a single array
    TEMPLATES = [
      JoyousCatTemplate,
      MailOrpheusTemplate,
      HCBStickersTemplate,
      KestrelHeidiTemplate,
      # HackatimeStickersTemplate,
      TarotTemplate,
      DinoWavingTemplate,
      HcpcxcTemplate,
      HackatimeTemplate,
      HeidiReadmeTemplate,
      GoodJobTemplate,
      HackatimeOTPTemplate,
      AthenaStickersTemplate,
      HCBWelcomePostcardTemplate,
    ].freeze

    # Default template to use when none is specified
    DEFAULT_TEMPLATE = KestrelHeidiTemplate

    class << self
      # Get all template classes
      def all
        TEMPLATES
      end

      # Get a template class by name
      def get_template_class(name)
        template_name = name.to_sym
        template_class = TEMPLATES.find { |t| t.template_name.to_sym == template_name }
        template_class || raise(TemplateNotFoundError, "Template not found: #{name}")
      end

      # Get a template instance for a letter
      # Options:
      #   template: Specifies the template to use, overriding any template in letter.rubber_stamps
      #   template_class: Pre-fetched template class to use (fastest option)
      def template_for(letter, options = {})
        # First check if template_class is provided (fastest path)
        if template_class = options[:template_class]
          return template_class.new(options)
        end

        # Next check if template name is specified in options
        template_name = options[:template]&.to_sym

        template_class = if template_name
            # Find template by name
            TEMPLATES.find { |t| t.template_name.to_sym == template_name }
          else
            # Use default
            DEFAULT_TEMPLATE
          end

        # Create a new instance of the template
        template_class ? template_class.new(options) : DEFAULT_TEMPLATE.new(options)
      end

      # Get templates by size
      def templates_by_size(size)
        size_sym = size.to_sym
        TEMPLATES.select { |t| t.template_size == size_sym }
      end

      # List all available template names
      def available_templates
        TEMPLATES.map { |t| t.template_name.to_sym }
      end

      def available_single_templates
        TEMPLATES.select { |t| t.show_on_single? }.map { |t| t.template_name.to_sym }
      end

      # Check if a template exists
      def template_exists?(name)
        TEMPLATES.any? { |t| t.template_name.to_sym == name.to_sym }
      end
    end
  end
end
