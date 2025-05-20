require "open3"
require "rmagick"

module SnailMail
  module Preview
    OUTPUT_DIR = Rails.root.join("app", "frontend", "images", "template_previews")

    class FakeAddress < OpenStruct
      def us_format
        <<~EOA
          #{name_line}
          #{[line_1, line_2].compact_blank.join("\n")}
          #{city}, #{state} #{postal_code}
          #{country}
        EOA
      end

      def us?
        country == "US"
      end

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

      return_address = OpenStruct.new(
        name: "Hack Club",
        line_1: "15 Falls Rd",
        city: "Shelburne",
        state: "VT",
        postal_code: "05482",
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

      Templates.available_templates.each do |name|
        template = Templates.get_template_class(name)
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
        pdf = SnailMail::Service.generate_label(mock_letter, template: name)

        png_path = OUTPUT_DIR.join("#{template.name.split("::").last.underscore}.png")

        begin
          image = Magick::Image.from_blob(pdf.render) do |i|
            i.density = 300
          end.first

          image.alpha(Magick::RemoveAlphaChannel)
          image.background_color = "white"
          image.pixel_interpolation_method = Magick::IntegerInterpolatePixel
          image.write(png_path)
        rescue => e
          Rails.logger.error("Failed to convert PDF to PNG: #{e.message}")
          raise e
        end
      end
    end
  end
end
