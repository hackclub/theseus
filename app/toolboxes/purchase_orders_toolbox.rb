# frozen_string_literal: true

class PurchaseOrdersToolbox < ApplicationToolbox
  before_action :require_warehouse!

  default_param :po_id, :integer, "Purchase order ID", except: %i[search create]

  # ── Read tools ──────────────────────────────────────────────

  tool "Search purchase orders by supplier name, order number, or notes", access: :read do
    param :query, :string, "Search term (matches supplier name, order number, notes)", optional: true
    param :status, :string, "Filter by status", optional: true, enum: %w[draft submitted approved returned open completed]
    param :page, :integer, "Page number", optional: true
  end
  def search
    scope = scoped_purchase_orders.includes(:user, :line_items).order(created_at: :desc)

    if params[:query].present?
      q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query])}%"
      scope = scope.where("supplier_name ILIKE ? OR order_number ILIKE ? OR notes ILIKE ?", q, q, q)
    end

    scope = scope.where(status: params[:status]) if params[:status].present?

    @purchase_orders = paginate(scope)
  end

  tool "Show full purchase order details with line items", access: :read do; end
  def show
    @purchase_order = find_purchase_order!
    @line_items = @purchase_order.line_items.includes(:sku, :sku_request)
  end

  # ── Write tools ─────────────────────────────────────────────

  tool "Create a new purchase order with line items", access: :write do
    param :supplier_name, :string, "Supplier name"
    param :supplier_id, :integer, "Supplier ID in Zenventory", optional: true
    param :notes, :string, "Notes for the order", optional: true
    param :required_by_date, :string, "Required by date (YYYY-MM-DD)", optional: true
    param :line_items, :"[:object]", "Line items for the order" do
      param :sku_id, :integer, "SKU ID (provide this or sku_request_id)", optional: true
      param :sku_request_id, :integer, "SKU request ID (for unresolved SKUs)", optional: true
      param :quantity, :integer, "Quantity to order"
      param :unit_cost, :number, "Unit cost", optional: true
    end
  end
  def create
    @purchase_order = Warehouse::PurchaseOrder.new(
      supplier_name: params[:supplier_name],
      supplier_id: params[:supplier_id],
      notes: params[:notes],
      required_by_date: params[:required_by_date],
      user: current_user
    )

    build_line_items!

    @purchase_order.save!
    @line_items = @purchase_order.line_items.includes(:sku, :sku_request)
    render :show
    suggests :submit, "Submit this PO for approval when ready"
  end

  tool "Update a draft or returned purchase order", access: :write do
    param :supplier_name, :string, "Supplier name", optional: true
    param :supplier_id, :integer, "Supplier ID in Zenventory", optional: true
    param :notes, :string, "Notes for the order", optional: true
    param :required_by_date, :string, "Required by date (YYYY-MM-DD)", optional: true
    param :line_items, :"[:object]", "Replacement line items (replaces all existing)", optional: true do
      param :sku_id, :integer, "SKU ID (provide this or sku_request_id)", optional: true
      param :sku_request_id, :integer, "SKU request ID (for unresolved SKUs)", optional: true
      param :quantity, :integer, "Quantity to order"
      param :unit_cost, :number, "Unit cost", optional: true
    end
  end
  def update
    @purchase_order = find_purchase_order!
    guard_editable!

    attrs = {}
    attrs[:supplier_name] = params[:supplier_name] if params[:supplier_name].present?
    attrs[:supplier_id] = params[:supplier_id] if params.key?(:supplier_id)
    attrs[:notes] = params[:notes] if params.key?(:notes)
    attrs[:required_by_date] = params[:required_by_date] if params.key?(:required_by_date)
    @purchase_order.assign_attributes(attrs)

    if params[:line_items].present?
      @purchase_order.line_items.destroy_all
      build_line_items!
    end

    @purchase_order.save!
    @line_items = @purchase_order.line_items.reload.includes(:sku, :sku_request)
    render :show
  end

  tool "Submit a draft purchase order for approval", access: :write do; end
  def submit
    po = find_purchase_order!
    halt error: "Only the owner can submit" unless po.user_id == current_user.id
    po.submit_for_approval!
    render json: { id: po.id, status: po.status, message: "Purchase order submitted for approval" }
  end

  # NOTE: approve is intentionally not exposed via MCP.
  # PO approval is a human judgment call — the whole point of the review workflow.
  # Use the web UI to approve POs.

  tool "Reject a submitted purchase order back for revision (warehouse czar only)", access: :write, scope: "warehouse_czar" do
    param :reviewer_notes, :string, "Reason for rejection", optional: true
  end
  def reject
    po = find_purchase_order!
    halt error: "Only warehouse czar can reject" unless current_user.warehouse_czar?
    ActiveRecord::Base.transaction do
      po.update!(reviewed_by: current_user, reviewer_notes: params[:reviewer_notes])
      po.return_for_revision!
    end
    render json: { id: po.id, status: po.status, message: "Purchase order returned for revision" }
  end

  tool "Return a rejected purchase order to draft for editing", access: :write do; end
  def revise
    po = find_purchase_order!
    halt error: "Only the owner or an admin can revise" unless po.user_id == current_user.id || admin?
    po.revise!
    render json: { id: po.id, status: po.status, message: "Purchase order returned to draft" }
  end

  tool "Send an approved purchase order to Zenventory (requires confirmation)", access: :write, scope: "warehouse_czar" do; end
  def send_to_zenventory
    po = find_purchase_order!
    halt error: "Only warehouse czar can dispatch to Zenventory" unless current_user.warehouse_czar?
    halt error: "Not all SKUs are resolved — resolve pending SKU requests first" unless po.all_skus_resolved?

    items_summary = po.line_items.includes(:sku).map { |li| "#{li.quantity}x #{li.sku&.name || "unresolved"}" }.join(", ")
    result = mcp_elicit(
      "Send PO ##{po.id} to Zenventory?\n\n" \
      "Supplier: #{po.supplier_name}\n" \
      "Items: #{items_summary}\n" \
      "Total: $#{"%.2f" % po.total_cost}\n\n" \
      "This will create a purchase order in Zenventory.",
      schema: {
        type: "object",
        properties: { confirmed: { type: "boolean", description: "Yes, send to Zenventory" } },
        required: ["confirmed"]
      }
    )
    halt error: "Dispatch cancelled" unless result["action"] == "accept" && result.dig("content", "confirmed")

    po.dispatch!
    render json: {
      id: po.id,
      status: po.status,
      zenventory_id: po.zenventory_id,
      order_number: po.order_number,
      message: "Purchase order sent to Zenventory"
    }
  end

  # NOTE: destroy is intentionally not exposed via MCP.
  # Deletion is irreversible and too dangerous for unattended LLM use.
  # Use the web UI to delete POs.

  private

  def scoped_purchase_orders
    if current_user.warehouse_czar? || admin?
      Warehouse::PurchaseOrder.all
    else
      Warehouse::PurchaseOrder.where(user: current_user)
    end
  end

  def find_purchase_order!
    scoped_purchase_orders.find(params[:po_id])
  end

  def guard_editable!(po = @purchase_order)
    unless po.draft? || po.returned?
      halt error: "Can only modify draft or returned purchase orders"
    end
    unless po.user_id == current_user.id || admin?
      halt error: "Only the owner or an admin can modify this purchase order"
    end
  end

  def build_line_items!
    (params[:line_items] || []).each do |li|
      @purchase_order.line_items.build(
        sku_id: li[:sku_id],
        sku_request_id: li[:sku_request_id],
        quantity: li[:quantity],
        unit_cost: li[:unit_cost]
      )
    end
  end
end
