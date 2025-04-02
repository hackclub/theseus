
module SnailMail
  module Templates
    class TemplateNotFoundError < StandardError; end

    # All available templates hardcoded in a single array
    TEMPLATES = [
      StandardTemplate,
      EnvelopeTemplate,
      CorporateEnvelopeTemplate,
      OrpheusTemplate,
      JoyousCatTemplate,
      MailOrpheusTemplate,
    ].freeze

    # Default template to use when none is specified
    DEFAULT_TEMPLATE = StandardTemplate

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
      #   template: Specifies the template to use, overriding any template in letter.extra_data
      #   template_class: Pre-fetched template class to use (fastest option)
      def template_for(letter, options = {})
        # First check if template_class is provided (fastest path)
        if template_class = options[:template_class]
          return template_class.new(options)
        end
        
        # Next check if template name is specified in options
        template_name = options[:template]&.to_sym
        
        # If no template in options, fall back to letter.extra_data
        template_name ||= extract_template_name(letter)
        
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
      
      # Check if a template exists
      def template_exists?(name)
        TEMPLATES.any? { |t| t.template_name.to_sym == name.to_sym }
      end

      private
      
      def extract_template_name(letter)
        return nil unless letter.respond_to?(:extra_data) && letter.extra_data.present?
        letter.extra_data.dig('template')&.to_sym
      end
    end
  end
end 