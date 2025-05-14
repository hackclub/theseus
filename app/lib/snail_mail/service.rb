require_relative "label_generator"
require_relative "templates"

module SnailMail
  class Service
    class Error < StandardError; end

    # Generate a label for a single letter and attach it to the letter
    def self.generate_label(letter, options = {})
      validate_letter(letter)
      template_name = options.delete(:template) || default_template

      generator = LabelGenerator.new(options)

      # Generate PDF without writing to disk
      pdf = generator.generate([letter], nil, [template_name])

      pdf
    end

    # Generate labels for a batch of letters and attach to batch
    def self.generate_batch_labels(letters, options = {})
      validate_batch(letters)

      template_cycle = options[:template_cycle]
      validate_template_cycle(template_cycle) if template_cycle

      # If no template cycle is provided, use the default template
      template_cycle ||= [default_template]

      # Get template classes once, avoid repeated lookups
      template_classes = template_cycle.map do |name|
        Templates.get_template_class(name)
      end

      # Ensure all templates in the cycle are of the same size
      template_sizes = template_classes.map(&:template_size).uniq
      if template_sizes.length > 1
        raise Error, "All templates in cycle must have the same size. Found: #{template_sizes.join(", ")}"
      end

      # Generate labels with template cycling without writing to disk
      generator = LabelGenerator.new(options)
      pdf = generator.generate(letters, nil, template_cycle)

      pdf
    end

    # List available templates
    def self.available_templates
      Templates.available_templates.uniq
    end

    # Get a list of all templates with their metadata
    def self.template_info
      Templates.all.map do |template_class|
        {
          name: template_class.template_name.to_sym,
          size: template_class.template_size,
          description: template_class.template_description,
          is_default: template_class == Templates::DEFAULT_TEMPLATE,
        }
      end
    end

    # Get templates for a specific size
    def self.templates_for_size(size)
      templates = Templates.templates_by_size(size)
      Rails.logger.info "Templates for size #{size}: Found #{templates.count} templates"

      template_names = templates.map do |template_class|
        begin
          name = template_class.template_name.to_s
          Rails.logger.info "  - Template: #{name}, Size: #{template_class.template_size}"
          name
        rescue => e
          Rails.logger.error "Error getting template name: #{e.message}"
          nil
        end
      end.compact

      Rails.logger.info "Final template names for size #{size}: #{template_names.inspect}"
      template_names
    end

    # Get the default template
    def self.default_template
      Templates::DEFAULT_TEMPLATE.template_name
    end

    # Check if templates exist
    def self.templates_exist?(template_names)
      Array(template_names).all? do |name|
        Templates.template_exists?(name)
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
