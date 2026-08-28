require "open3"
require "rmagick"
require "parallel"

module SnailMail
  module Preview
    OUTPUT_DIR = Rails.root.join("app", "frontend", "images", "template_previews")
    PREVIEW_DPI = 150

    class FakeAddress < OpenStruct
      def us_format
        <<~EOA
          #{name_line}
          #{[line_1, line_2].compact_blank.join("\n")}
          #{city}, #{state} #{postal_code}
          #{country}
        EOA
      end

      def us? = country == "US"

      def snailify(origin = "US")
        SnailButNbsp.new(
          name: name_line,
          line_1:,
          line_2: line_2.presence,
          city:,
          region: state,
          postal_code:,
          country: country,
          origin: origin,
        ).to_s
      end
    end

    def self.generate_previews
      OUTPUT_DIR.mkpath

      templates = SnailMail::Components::Registry.available_templates
      Rails.logger.info("Generating #{templates.size} template previews in parallel...")

      Parallel.each(templates, in_threads: Parallel.processor_count, progress: "Generating previews") do |name|
        generate_single_preview(name)
      end

      Rails.logger.info("Finished generating #{templates.size} template previews")
    end

    def self.generate_single_preview(name)
      return_address = OpenStruct.new(
        name: "Hack Club",
        line_1: "212 Battery St",
        line_2: "Suite 3",
        city: "Burlington",
        state: "VT",
        postal_code: "05401",
        country: "US",
      )

      names = [
        "Orpheus",
        "Heidi Hakkuun",
        "Dinobox",
        "Arcadius",
        "Cap'n Trashbeard",
      ]

      usps_mailer_id = OpenStruct.new(mid: "111111")

      template = SnailMail::Components::Registry.get_component_class(name)
      sender, recipient = names.sample(2)

      mock_letter = OpenStruct.new(
        address: FakeAddress.new(
          line_1: "8605 Santa Monica Blvd",
          line_2: "Apt. 86294",
          city: "West Hollywood",
          state: "CA",
          postal_code: "90069",
          country: "US",
          name_line: sender,
        ),
        return_address:,
        return_address_name_line: recipient,
        postage_type: "stamps",
        postage: 0.73,
        usps_mailer_id:,
        imb_serial_number: "1337",
        metadata: {},
        rubber_stamps: "here's where rubber stamps go!",
        public_id: "ltr!PR3V13W",
      )

      Rails.logger.info("generating preview for #{name}...")
      pdf = SnailMail::PhlexService.generate_label(mock_letter, template: name)
      pdf_data = pdf.render

      png_path = OUTPUT_DIR.join("#{template.name.split("::").last.underscore}.png")

      convert_pdf_to_png(pdf_data, png_path)
    end

    def self.convert_pdf_to_png(pdf_data, png_path)
      if pdftoppm_available?
        convert_with_pdftoppm(pdf_data, png_path)
      else
        convert_with_rmagick(pdf_data, png_path)
      end
    end

    def self.pdftoppm_available?
      @pdftoppm_available ||= system("which pdftoppm > /dev/null 2>&1")
    end

    def self.convert_with_pdftoppm(pdf_data, png_path)
      base_path = png_path.to_s.sub(/\.png$/, "")

      Open3.popen3("pdftoppm", "-png", "-r", PREVIEW_DPI.to_s, "-singlefile", "-", base_path) do |stdin, stdout, stderr, wait_thr|
        stdin.binmode
        stdin.write(pdf_data)
        stdin.close

        unless wait_thr.value.success?
          raise "pdftoppm failed: #{stderr.read}"
        end
      end
    end

    def self.convert_with_rmagick(pdf_data, png_path)
      image = Magick::Image.from_blob(pdf_data) do |i|
        i.density = PREVIEW_DPI
      end.first

      image.alpha(Magick::RemoveAlphaChannel)
      image.background_color = "white"
      image.write(png_path)
    rescue => e
      Rails.logger.error("Failed to convert PDF to PNG: #{e.message}")
      raise e
    end
  end
end
