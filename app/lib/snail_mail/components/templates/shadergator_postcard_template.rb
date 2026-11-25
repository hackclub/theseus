# frozen_string_literal: true

require "stringio"
require "uri"

module SnailMail
  module Components
    module Templates
      # ShaderGator's postcard. The front is a PNG or JPEG that ShaderGator renders
      # from a shader and serves over https. The letter's metadata carries:
      #
      #   front_url    https URL of the front image (host must be in ALLOWED_FRONT_HOSTS)
      #   shader_name  name of the shader, drawn on the fallback front and on the back
      #   maker_name   optional, printed on the back as "by <name>"
      #   gallery_url  optional, printed on the back as text
      class ShadergatorPostcardTemplate < HalfLetterComponent
        # Hosts that may serve front images. Theseus never fetches any other host.
        # TODO: confirm with ShaderGator whether front images also come from another host.
        ALLOWED_FRONT_HOSTS = %w[shadergator.hackclub.com].freeze
        FETCH_TIMEOUT_SECONDS = 10
        MAX_FRONT_BYTES = 5 * 1024 * 1024
        FALLBACK_IMAGE = "shadergator/fallback-front.png"
        MAX_TEXT_LENGTH = 80

        class FrontTooLarge < StandardError; end

        def self.abstract? = false

        def self.template_name = "shadergator_postcard"

        def self.template_size = :half_letter

        def self.show_on_single? = false

        def self.template_description = "ShaderGator postcard: the front is the person's shader"

        def render_front
          io = fetch_front_image
          if io
            begin
              image(io, at: [ 0, bounds.top ], fit: [ bounds.width, bounds.height ], position: :center, vposition: :center)
              return
            rescue StandardError => e
              Rails.logger.warn("shadergator_postcard: could not draw front image: #{e.class}")
            end
          end

          render_fallback_front
        end

        def render_back
          super
          render_shader_credit
        end

        private

        def meta
          letter.metadata.is_a?(Hash) ? letter.metadata : {}
        end

        def clean_text(value)
          value.to_s.gsub(/[[:cntrl:]]+/, " ").squish.truncate(MAX_TEXT_LENGTH)
        end

        # The postage is already bought when this runs, so it must never raise.
        def fetch_front_image
          uri = allowed_front_uri(meta["front_url"])
          return nil unless uri

          body = +"".b
          response = Faraday.new(request: { timeout: FETCH_TIMEOUT_SECONDS, open_timeout: FETCH_TIMEOUT_SECONDS }) do |f|
            f.headers["User-Agent"] = "Theseus-ShaderGatorPostcard"
          end.get(uri.to_s) do |req|
            req.options.on_data = proc do |chunk, _received|
              body << chunk
              raise FrontTooLarge if body.bytesize > MAX_FRONT_BYTES
            end
          end

          return nil unless response.status == 200 # redirects are not followed
          return nil unless response.headers["content-type"].to_s.downcase.start_with?("image/png", "image/jpeg")
          return nil unless image_signature?(body)

          StringIO.new(body)
        rescue StandardError => e
          Rails.logger.warn("shadergator_postcard: front fetch failed: #{e.class}")
          nil
        end

        def allowed_front_uri(value)
          return nil unless value.is_a?(String)

          uri = URI.parse(value.strip)
          return nil unless uri.is_a?(URI::HTTPS)
          return nil if uri.userinfo || uri.port != 443
          return nil unless ALLOWED_FRONT_HOSTS.include?(uri.host.to_s.downcase)

          uri
        rescue URI::InvalidURIError
          nil
        end

        def image_signature?(body)
          body.start_with?("\x89PNG\r\n\x1A\n".b) || body.start_with?("\xFF\xD8\xFF".b)
        end

        def render_fallback_front
          image(image_path(FALLBACK_IMAGE), at: [ 0, bounds.top ], width: bounds.width, height: bounds.height)

          name = clean_text(meta["shader_name"])
          fill_color "FFFFFF"
          font("arial") do
            text_box("ShaderGator", at: [ 40, bounds.top - 40 ], width: bounds.width - 80, size: 22)
            if name.present?
              text_box(name, at: [ 40, 190 ], width: bounds.width - 80, height: 110, size: 44, valign: :bottom, overflow: :shrink_to_fit)
            end
          end
          fill_color "000000"
        end

        # Sits in the free strip at the bottom left of the back, clear of the
        # QR code, the destination address, the postage and the barcode.
        def render_shader_credit
          name = clean_text(meta["shader_name"])
          maker = clean_text(meta["maker_name"])
          gallery = gallery_text(meta["gallery_url"])
          return if name.blank? && maker.blank? && gallery.blank?

          font(address_font) do
            fill_color "000000"
            lines = []
            lines << [ name, 11 ] if name.present?
            lines << [ "by #{maker}", 9 ] if maker.present?
            lines << [ gallery, 8 ] if gallery.present?

            y = 112
            lines.each do |line, size|
              text_box(line, at: [ 15, y ], width: 355, height: size + 4, size: size, overflow: :shrink_to_fit)
              y -= size + 6
            end
          end
        end

        def gallery_text(value)
          return nil unless value.is_a?(String)

          uri = URI.parse(value.strip)
          return nil unless uri.is_a?(URI::HTTPS) && uri.host.present?

          clean_text(value.strip.sub(%r{\Ahttps://}i, ""))
        rescue URI::InvalidURIError
          nil
        end
      end
    end
  end
end
