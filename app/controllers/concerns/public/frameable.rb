module Public::Frameable
  extend ActiveSupport::Concern
  included do
    layout "public/frameable"

    def set_framed
      @framed = request.headers["Sec-Fetch-Dest"] == "iframe"
    end

    before_action :set_framed

    def frame_aware_redirect_to(path, **options)
      if @framed
        redirect_to "#{path}#{path.include?('?') ? '&' : '?'}framed=true", **options
      else
        redirect_to path, **options
      end
    end

    private

    def add_framed_param(path)
      uri = URI.parse(path)
      params = URI.decode_www_form(uri.query || '')
      params << ['framed', @framed]
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end
  end
end