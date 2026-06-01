class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :api_docs]
  skip_after_action :verify_authorized
  before_action :require_admin!, only: [:problems]

  def index
    @stats = DashboardStats.new(user: current_user)
  end

  def login
    render :login, layout: false
  end

  def api_docs
    respond_to do |format|
      format.html do
        markdown = Rails.root.join("app", "views", "static_pages", "api_docs.md").read
        render Components::StaticPages::APIDocs.new(markdown:)
      end
      format.md do
        llm_markdown = Rails.root.join("app", "views", "static_pages", "api_docs_llm.md").read
        render plain: llm_markdown, content_type: "text/markdown"
      end
    end
  end

  def problems
    enabled = Warehouse::SKU.where(enabled: true)
    @blocking = enabled.select { |s| !s.declared_unit_cost.positive? }
    @no_po_cost = enabled.where(average_po_cost: [nil, 0]).reject { |s| @blocking.include?(s) }
    @backordered = enabled.where("in_stock < 0").where("inbound IS NULL OR inbound < ABS(in_stock)")
    @stuck_orders = Warehouse::Order.where(aasm_state: "dispatched")
                      .where("dispatched_at < ?", 14.days.ago)
  end

  private

  def require_admin!
    redirect_to root_path, alert: "you can't do that!" unless current_user&.admin?
  end
end
