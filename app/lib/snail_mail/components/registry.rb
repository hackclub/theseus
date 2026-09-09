module SnailMail
  module Components
    class Registry
      class ComponentNotFoundError < StandardError; end

      # Default component to use when none is specified
      DEFAULT_TEMPLATE_NAME = "kestrel's heidi template!"

      class << self
        # Get all template classes using descendants, excluding abstract ones
        def all
          TemplateBase.descendants.reject(&:abstract?)
        end

        # Get a component class by name
        def get_component_class(name)
          component_name = name.to_sym
          component_class = all.find { |c| c.template_name.to_sym == component_name }
          component_class || raise(ComponentNotFoundError, "Component not found: #{name}")
        end

        # Get a component instance for a letter
        def component_for(letter, options = {})
          # Check if component name is specified in options
          component_name = options[:template]&.to_sym

          component_class = if component_name
              # Find component by name
              all.find { |c| c.template_name.to_sym == component_name }
          else
              # Use default
              default_component_class
          end

          # Create a new instance of the component
          component_class ||= default_component_class
          component_class.new(letter: letter, **options)
        end

        # Get components by size
        def components_by_size(size)
          size_sym = size.to_sym
          all.select { |c| c.template_size == size_sym }
        end

        # List all available component names
        def available_templates
          all.map { |c| c.template_name.to_sym }
        end

        def available_single_templates
          all.select { |c| c.show_on_single? }.map { |c| c.template_name.to_sym }
        end

        # Check if a component exists
        def template_exists?(name)
          all.any? { |c| c.template_name.to_sym == name.to_sym }
        end

        # Get the default template name
        def default_template
          DEFAULT_TEMPLATE_NAME
        end

        # Get the default component class
        def default_component_class
          all.find { |c| c.template_name == DEFAULT_TEMPLATE_NAME }
        end

        # Get template info for all components
        def template_info
          all.map do |component_class|
            {
              name: component_class.template_name.to_sym,
              size: component_class.template_size,
              description: component_class.template_description,
              is_default: component_class.template_name == DEFAULT_TEMPLATE_NAME
            }
          end
        end

        # Get templates for a specific size
        def templates_for_size(size)
          components = components_by_size(size)
          Rails.logger.info "Components for size #{size}: Found #{components.count} components"

          template_names = components.map do |component_class|
            begin
              name = component_class.template_name.to_s
              Rails.logger.info "  - Component: #{name}, Size: #{component_class.template_size}"
              name
            rescue => e
              Rails.logger.error "Error getting component name: #{e.message}"
              nil
            end
          end.compact

          Rails.logger.info "Final template names for size #{size}: #{template_names.inspect}"
          template_names
        end
      end
    end
  end
end
