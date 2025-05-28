module SnailMail
  class BaseTemplate
    include SnailMail::Helpers

    # Template sizes in points [width, height]
    SIZES = {
      standard: [6 * 72, 4 * 72], # 4x6 inches (432 x 288 points)
      envelope: [9.5 * 72, 4.125 * 72], # #10 envelope (684 x 297 points)
      half_letter: [8 * 72, 5 * 72], # half-letter (576 x 360 points)
    }.freeze

    # Template metadata - override in subclasses
    def self.template_name
      name.demodulize.underscore.sub(/_template$/, "")
    end

    def self.template_size
      :standard # default to 4x6 standard
    end

    def self.show_on_single?
      false
    end

    def self.template_description
      "A label template"
    end

    # Instance methods
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    # Size in points [width, height]
    def size
      SIZES[self.class.template_size] || SIZES[:standard]
    end

    # Main render method, to be implemented by subclasses
    def render(pdf, letter)
      raise NotImplementedError, "Subclasses must implement the render method"
    end

    protected

    # Helper methods for templates

    # Render return address
    def render_return_address(pdf, letter, x, y, width, height, options = {})
      default_options = {
        font: "arial",
        size: 11,
        align: :left,
        valign: :top,
        overflow: :shrink_to_fit,
        min_font_size: 6,
      }

      options = default_options.merge(options)
      font_name = options.delete(:font)

      pdf.font(font_name) do
        pdf.text_box(
          format_return_address(letter, options[:no_name_line]),
          at: [x, y],
          width: width,
          height: height,
          **options,
        )
      end
    end

    # Render destination address
    def render_destination_address(pdf, letter, x, y, width, height, options = {})
      default_options = {
        font: "f25",
        size: 11,
        align: :left,
        valign: :center,
        overflow: :shrink_to_fit,
        min_font_size: 6,
        disable_wrap_by_char: true,
      }

      options = default_options.merge(options)
      font_name = options.delete(:font)
      stroke = options.delete(:dbg_stroke)

      pdf.font(font_name) do
        pdf.text_box(
          letter.address.snailify(letter.return_address.country),
          at: [x, y],
          width: width,
          height: height,
          **options,
        )
      end
      if stroke
        pdf.stroke { pdf.rectangle([x, y], width, height) }
      end
    end

    # Render Intelligent Mail barcode
    def render_imb(pdf, letter, x, y, width, options = {})

      # we want an IMb if:
      # - the letter is US-to-US (end-to-end IV)
      # - the letter is US-to-non-US (IV until it's out of the US)
      # - the letter is non-US-to-US (IV after it enters the US)
      # but not if
      # - the letter is non-US-to-non-US (that'd be pretty stupid)

      return unless letter.address.us? || letter.return_address.us?

      default_options = {
        font: "imb",
        size: 24,
        align: :center,
        overflow: :shrink_to_fit,
      }

      options = default_options.merge(options)
      font_name = options.delete(:font)

      pdf.font(font_name) do
        pdf.text_box(
          generate_imb(letter),
          at: [x, y],
          width: width,
          disable_wrap_by_char: true,
          **options,
        )
      end
    end

    # Render QR code
    def render_qr_code(pdf, letter, x, y, size = 70)
      return unless options[:include_qr_code]
      SnailMail::QRCodeGenerator.generate_qr_code(pdf, "https://hack.club/#{letter.public_id}", x, y, size)
      pdf.font("f25") do
        pdf.text_box("scan this so we know you got it!", at: [x + 3, y + 22], width: 54, size: 6.4)
      end
    end

    def render_letter_id(pdf, letter, x, y, size, opts = {})
      return if options[:include_qr_code]
      pdf.font(opts.delete(:font) || "f25") { pdf.text_box(letter.public_id, at: [x, y], size:, overflow: :shrink_to_fit, valign: :top, **opts) }
    end

    private

    # Format destination address
    def format_destination_address(letter)
      letter.address.snailify(letter.return_address.country)
    end

    # Generate IMb barcode
    def generate_imb(letter)
      # Use the IMb module to generate the barcode
      IMb.new(letter).generate
    end

    def render_postage(pdf, letter, x = pdf.bounds.right - 138)
      if letter.postage_type == "indicia"
        IMI.render_indicium(pdf, letter, letter.usps_indicium, x)
        FIM.render_fim_d(pdf, x - 62)
      elsif letter.postage_type == "stamps"
        postage_amount = letter.postage
        stamps = USPS::McNuggetEngine.find_stamp_combination(postage_amount)

        requested_stamps = if stamps.size == 1
            stamp = stamps.first
            "#{stamp[:count]} #{stamp[:name]}"
          elsif stamps.size == 2
            "#{stamps[0][:count]} #{stamps[0][:name]} and #{stamps[1][:count]} #{stamps[1][:name]}"
          else
            stamps.map.with_index do |stamp, index|
              if index == stamps.size - 1
                "and #{stamp[:count]} #{stamp[:name]}"
              else
                "#{stamp[:count]} #{stamp[:name]}"
              end
            end.join(", ")
          end

        postage_info = <<~EOT
          i take #{ActiveSupport::NumberHelper.number_to_currency(postage_amount)} in postage, so #{requested_stamps}
        EOT

        pdf.bounding_box([pdf.bounds.right - 55, pdf.bounds.top - 5], width: 50, height: 50) do
          pdf.font("f25") do
            pdf.text_box(
              postage_info,
              at: [1, 48],
              width: 48,
              height: 45,
              size: 8,
              align: :center,
              min_font_size: 4,
              overflow: :shrink_to_fit,
            )
          end
        end
      else
        pdf.bounding_box([pdf.bounds.right - 55, pdf.bounds.top - 5], width: 52, height: 50) do
          pdf.font("f25") do
            pdf.text_box("please affix however much postage your post would like", at: [1, 48], width: 50, height: 45, size: 8, align: :center, min_font_size: 4, overflow: :shrink_to_fit)
          end
        end
      end
    end

    def format_return_address(letter, no_name_line = false)
      return_address = letter.return_address
      return "No return address" unless return_address

      <<~EOA
        #{letter.return_address_name_line unless no_name_line}
        #{[return_address.line_1, return_address.line_2].compact_blank.join("\n")}
        #{return_address.city}, #{return_address.state} #{return_address.postal_code}
        #{return_address.country if return_address.country != letter.address.country}
      EOA
        .strip
    end
  end
end
