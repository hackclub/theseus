class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def internal_server_error
    @sentry_event_id = request.env["sentry.error_event_id"] || Sentry.last_event_id
    render status: :internal_server_error, formats: [ :html ]
  end
end
