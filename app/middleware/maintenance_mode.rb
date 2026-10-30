require "json"

class MaintenanceMode
  PUBLIC_HTML = File.read(File.expand_path("../../public/503.html", __dir__)).freeze
  BACK_OFFICE_HTML = File.read(File.expand_path("../../public/503_back_office.html", __dir__)).freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless ENV["MAINTENANCE_MODE"]

    if env["PATH_INFO"] == "/up" || env["PATH_INFO"] == "/maintenance.jpg"
      return @app.call(env)
    end

    if env["PATH_INFO"].start_with?("/api/")
      body = { error: "service_unavailable", message: "Theseus is down for planned maintenance." }
      body[:message] += " Check the thread in #hq-hq for updates." unless env["PATH_INFO"].start_with?("/api/public/")
      return [ 503, { "content-type" => "application/json", "retry-after" => "300" }, [ body.to_json ] ]
    end

    html = env["PATH_INFO"].start_with?("/back_office") ? BACK_OFFICE_HTML : PUBLIC_HTML
    [ 503, { "content-type" => "text/html", "retry-after" => "300" }, [ html ] ]
  end
end
