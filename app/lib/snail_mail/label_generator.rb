require "prawn"
require "securerandom"
require_relative "templates"

module SnailMail
  class LabelGenerator
    class Error < StandardError; end

    attr_reader :options

    def initialize(options = {})
      @options = {
        margin: 0,
      }.merge(options)
    end

    # Generate labels for a collection of letters
    # template_names: array of template names to cycle through
    # Returns the PDF object directly (doesn't write to disk unless output_path provided)
    def generate(letters, output_path = nil, template_names)
      raise Error, "No letters provided" if letters.empty?
      raise Error, "No template names provided" if template_names.empty?

      begin
        # Get template classes upfront to avoid repeated lookups
        template_classes = template_names.map do |name|
          Templates.get_template_class(name)
        end

        # Ensure all template sizes are the same
        sizes = template_classes.map(&:template_size).uniq
        if sizes.length > 1
          raise Error, "Mixed template sizes in batch (#{sizes.join(", ")}). All templates must have the same size."
        end

        # Create template lookup for faster access
        template_lookup = {}
        template_names.each_with_index do |name, i|
          template_lookup[name] = template_classes[i]
        end

        # All templates have the same size, create one PDF
        pdf = create_document(sizes.first)

        letters.each_with_index do |letter, index|
          template_name = template_names[index % template_names.length]
          render_letter(pdf, letter, template: template_name, template_class: template_lookup[template_name])
          pdf.start_new_page unless index == letters.length - 1
        end

        # Write to disk only if output_path is provided
        pdf.render_file(output_path) if output_path

        # Return the PDF object
        pdf
      rescue => e
        Rails.logger.error("Failed to generate labels: #{e.message}")
        raise
      end
    end

    private

    def create_document(page_size_name)
      page_size = BaseTemplate::SIZES[page_size_name] || BaseTemplate::SIZES[:standard]

      pdf = Prawn::Document.new(
        page_size: page_size,
        margin: @options[:margin],
      )

      register_fonts(pdf)
      pdf.fallback_fonts(["arial", "noto"])
      pdf
    end

    def register_fonts(pdf)
      pdf.font_families.update(
        "comic" => { normal: font_path("comic sans.ttf") },
        "arial" => { normal: font_path("arial.otf") },
        "f25" => { normal: font_path("f25.ttf") },
        "imb" => { normal: font_path("imb.ttf") },
        "gohu" => { normal: font_path("gohu.ttf") },
        "noto" => { normal: font_path("noto sans regular.ttf") },
      )
    end

    def font_path(font_name)
      File.join(Rails.root, "app", "lib", "snail_mail", "assets", "fonts", font_name)
    end

    def render_letter(pdf, letter, letter_options = {})
      template_options = @options.merge(letter_options)

      # Use pre-fetched template class if provided, otherwise look it up
      if template_class = letter_options[:template_class]
        template = template_class.new(template_options)
      else
        template = Templates.template_for(letter, template_options)
      end

      template.render(pdf, letter)
    end
  end
end
