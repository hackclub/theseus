module SnailMail
  class BaseTemplate
    # Template sizes in points [width, height]
    SIZES = {
      standard: [6 * 72, 4 * 72], # 4x6 inches (432 x 288 points)
      envelope: [9.5 * 72, 4.125 * 72] # #10 envelope (684 x 297 points)
    }.freeze
    
    # Template metadata - override in subclasses
    def self.template_name
      name.demodulize.underscore.sub(/_template$/, '')
    end
    
    def self.template_size
      :standard # default to 4x6 standard
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
        font: 'comic',
        size: 9,
        align: :left,
        valign: :top,
        overflow: :shrink_to_fit,
        min_font_size: 6
      }
      
      options = default_options.merge(options)
      font_name = options.delete(:font)
      
      pdf.font(font_name) do
        pdf.text_box(
          format_return_address(letter),
          at: [x, y],
          width: width,
          height: height,
          **options
        )
      end
    end
    
    # Render destination address
    def render_destination_address(pdf, letter, x, y, width, height, options = {})
      default_options = {
        font: 'f25',
        size: 11,
        align: :left,
        valign: :center,
        overflow: :shrink_to_fit,
        min_font_size: 6
      }
      
      options = default_options.merge(options)
      font_name = options.delete(:font)
      
      pdf.font(font_name) do
        pdf.text_box(
          letter.address.snailify,
          at: [x, y],
          width: width,
          height: height,
          **options
        )
      end
    end
    
    # Render Intelligent Mail barcode
    def render_imb(pdf, letter, x, y, width, options = {})
      return unless letter.address.us?
      
      default_options = {
        font: 'imb',
        size: 24,
        align: :center,
        overflow: :shrink_to_fit
      }
      
      options = default_options.merge(options)
      font_name = options.delete(:font)
      
      pdf.font(font_name) do
        pdf.text_box(
          generate_imb(letter),
          at: [x, y],
          width: width,
          disable_wrap_by_char: true,
          **options
        )
      end
    end
    
    # Render QR code
    def render_qr_code(pdf, letter, x, y, size = 80)
      return unless options[:include_qr_code]
      SnailMail::QRCodeGenerator.generate_qr_code(pdf, "https://mail.hack.club/#{letter.public_id}", x, y, size)
    end
    
    # Helper for path to image assets
    def image_path(image_name)
      File.join(Rails.root, "app", "lib", "snail_mail", "assets", "images", image_name)
    end
    
    private
    
    # Format return address
    def format_return_address(letter)
      letter.return_address
    end
    
    # Format destination address
    def format_destination_address(letter)
      letter.address.snailify
    end
    
    # Generate IMb barcode
    def generate_imb(letter)
      # Use the IMb module to generate the barcode
      IMb.new(letter).generate
    end

  end
end 