class ApplicationToolbox < Toolchest::Toolbox
  include Pundit::Authorization

  helper_method :current_user, :admin?, :can_warehouse?

  def current_user = auth&.resource_owner

  def admin? = current_user&.admin?

  def can_warehouse? = current_user&.can_warehouse? || admin?

  rescue_from ActiveRecord::RecordNotFound do |e|
    model_name = e.model&.demodulize&.titleize || "record"
    render_error "Couldn't find that #{model_name.downcase}"
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render_errors e.record
  end

  rescue_from AASM::InvalidTransition do |e|
    render_error "Can't do that right now — wrong state"
  end

  private

  def require_admin!
    halt error: "Forbidden — admin only" unless admin?
  end

  def require_warehouse!
    halt error: "Forbidden — warehouse access required" unless can_warehouse?
  end

  def paginate(scope, per: 25)
    page = (params[:page] || 1).to_i
    scope.page(page).per(per)
  end
end
