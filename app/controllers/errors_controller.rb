class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def internal_server_error
    @sentry_event_id = request.env["sentry.error_event_id"] || Sentry.last_event_id

    if wants_json?
      render json: { error: "internal_error", sentry_event_id: @sentry_event_id }.compact_blank,
        status: :internal_server_error
    else
      render status: :internal_server_error, formats: [ :html ]
    end
  end

  private

  # Anything that blew up before it reached a controller (a malformed JSON body,
  # say) lands here, and an API client should never be handed a web page.
  def wants_json?
    request.get_header("action_dispatch.original_path").to_s.start_with?("/api/") || request.format.json?
  end
end
