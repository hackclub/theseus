require_relative "components"

module SnailMail
  class PhlexService
    class Error < StandardError; end

    # Generate a label for a single letter using Phlex::PDF
    def self.generate_label(letter, options = {})
      validate_letter(letter)
      template_name = options.delete(:template) || default_template

      # Get page size from component class
      component_class = Components::Registry.get_component_class(template_name)
      page_size = Components::BaseComponent::SIZES[component_class.template_size] || Components::BaseComponent::SIZES[:standard]
      
      # Create component
      component = Components::Registry.component_for(letter, options.merge(template: template_name))
      
      # Use a simple wrapper approach - create the PDF and delegate methods to the component
      class << component
        attr_accessor :document
        
        # Override method_missing to delegate to the document when needed
        def method_missing(method_name, *args, **kwargs, &block)
          if document && document.respond_to?(method_name)
            document.send(method_name, *args, **kwargs, &block)
          else
            super
          end
        end
        
        def respond_to_missing?(method_name, include_private = false)
          (document && document.respond_to?(method_name, include_private)) || super
        end
      end
      
      # Create Prawn document and set it on the component
      component.document = Prawn::Document.new(
        page_size: page_size,
        margin: options[:margin] || 0,
      )
      
      # Call the component's template methods
      component.before_template if component.respond_to?(:before_template)
      component.view_template
      component.after_template if component.respond_to?(:after_template)
      
      component.document
    end

    # Generate labels for a batch of letters using Phlex::PDF
    def self.generate_batch_labels(letters, options = {})
      validate_batch(letters)

      template_cycle = options[:template_cycle]
      validate_template_cycle(template_cycle) if template_cycle

      # If no template cycle is provided, use the default template
      template_cycle ||= [default_template]

      # Get component classes once, avoid repeated lookups
      component_classes = template_cycle.map do |name|
        Components::Registry.get_component_class(name)
      end

      # Ensure all templates in the cycle are of the same size
      template_sizes = component_classes.map(&:template_size).uniq
      if template_sizes.length > 1
        raise Error, "All templates in cycle must have the same size. Found: #{template_sizes.join(", ")}"
      end

      # Create combined document with proper page size
      page_size = Components::BaseComponent::SIZES[template_sizes.first] || Components::BaseComponent::SIZES[:standard]
      combined_pdf = Prawn::Document.new(
        page_size: page_size,
        margin: options[:margin] || 0,
      )

      letters.each_with_index do |letter, index|
        template_name = template_cycle[index % template_cycle.length]
        component = Components::Registry.component_for(letter, options.merge(template: template_name))
        
        # Use the same method delegation approach as single label generation
        class << component
          attr_accessor :document
          
          def method_missing(method_name, *args, **kwargs, &block)
            if document && document.respond_to?(method_name)
              document.send(method_name, *args, **kwargs, &block)
            else
              super
            end
          end
          
          def respond_to_missing?(method_name, include_private = false)
            (document && document.respond_to?(method_name, include_private)) || super
          end
        end
        
        # Start new page for subsequent letters
        if index > 0
          combined_pdf.start_new_page
        end

        # Set the document context and render
        component.document = combined_pdf
        begin
          component.before_template if component.respond_to?(:before_template)
          component.view_template
          component.after_template if component.respond_to?(:after_template)
        rescue Prawn::Errors::CannotFit => e
          address = letter.address
          raise Error, "Letter #{letter.id} (\"#{address&.line1}\", #{address&.city}, #{address&.state}) – address too long to fit on label"
        end
      end

      combined_pdf
    end

    # List available templates
    def self.available_templates = Components::Registry.available_templates.uniq

    # Get a list of all templates with their metadata
    def self.template_info = Components::Registry.template_info

    # Get templates for a specific size
    def self.templates_for_size(size) = Components::Registry.templates_for_size(size)

    # Get the default template
    def self.default_template = Components::Registry.default_template

    # Check if templates exist
    def self.templates_exist?(template_names)
      Array(template_names).all? do |name|
        Components::Registry.template_exists?(name)
      end
    end

    private

    def self.validate_letter(letter)
      raise Error, "Letter cannot be nil" unless letter
      raise Error, "Letter must have an address" unless letter.respond_to?(:address) && letter.address
    end

    def self.validate_batch(letters)
      raise Error, "Letters cannot be nil" unless letters
      raise Error, "Letters must be a collection" unless letters.respond_to?(:each)
      raise Error, "Letters collection cannot be empty" if letters.empty?
    end

    def self.validate_template_cycle(template_cycle)
      raise Error, "Template cycle must be an array" unless template_cycle.is_a?(Array)
      raise Error, "Template cycle cannot be empty" if template_cycle.empty?

      invalid_templates = template_cycle.reject { |name| templates_exist?([name]) }
      if invalid_templates.any?
        raise Error, "Invalid templates in cycle: #{invalid_templates.join(", ")}"
      end
    end
  end
end
