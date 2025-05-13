require "rqrcode"
require "prawn"
require "stringio"

module SnailMail
  class QRCodeGenerator
    DEFAULT_SIZE = 80
    DEFAULT_QR_OPTIONS = {
      bit_depth: 1,
      border_modules: 1,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_gte_to: false,
      resize_exactly_to: false,
      size: 120,
    }.freeze

    # Generate a QR code and add it to the PDF
    def self.generate_qr_code(pdf, content, x, y, size = DEFAULT_SIZE)
      raise ArgumentError, "PDF document cannot be nil" unless pdf
      raise ArgumentError, "QR code content cannot be empty" if content.to_s.empty?

      begin
        qr = RQRCode::QRCode.new(content)
        png = qr.as_png(DEFAULT_QR_OPTIONS)

        # Use StringIO instead of tempfile
        io = StringIO.new
        png.write(io)
        io.rewind

        # Add the PNG to the PDF without creating a file
        pdf.image io, at: [x, y], width: size, height: size
      rescue => e
        Rails.logger.error("QR code generation failed: #{e.message}")
        uuid = Honeybadger.notify(e)
        # Fallback to a text label if QR code fails
        pdf.text_box "QR Error (error: #{uuid})", at: [x, y], width: size, height: size
      end
    end
  end
end
