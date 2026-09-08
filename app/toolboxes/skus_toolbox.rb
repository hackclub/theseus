class SKUsToolbox < ApplicationToolbox
  before_action :require_warehouse!
  before_action :require_admin!, only: [:update]

  default_param :sku_id, :integer, "SKU ID", except: [:search, :inventory, :backordered]

  tool "Search warehouse SKUs by name, SKU code, or description", access: :read do
    param :query, :string, "Search term", optional: true
    param :category, :string, "Filter by category", optional: true, enum: Warehouse::SKU.categories.keys
    param :include_non_inventory, :boolean, "Include non-inventory SKUs (default false)", optional: true, default: false
    param :page, :integer, "Page number", optional: true
  end
  def search
    scope = params[:include_non_inventory] ? Warehouse::SKU.all : Warehouse::SKU.in_inventory

    if params[:query].present?
      q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query])}%"
      scope = scope.where("name ILIKE ? OR sku ILIKE ? OR description ILIKE ?", q, q, q)
    end

    scope = scope.where(category: params[:category]) if params[:category].present?

    @skus = paginate(scope.order(:name))
  end

  tool "Show full SKU details including stock, recent orders, and outstanding POs", access: :read
  def show
    load_sku_with_associations
  end

  tool "Update SKU attributes (admin only)", access: :write, scope: "admin" do
    param :name, :string, "SKU name", optional: true
    param :description, :string, "SKU description", optional: true
    param :enabled, :boolean, "Whether SKU is enabled", optional: true
    param :ai_enabled, :boolean, "Whether SKU is available for AI selection", optional: true
    param :category, :string, "SKU category", optional: true, enum: Warehouse::SKU.categories.keys
    param :country_of_origin, :string, "Country of origin code", optional: true
    param :hs_code, :string, "Harmonized System code for customs", optional: true
    param :customs_description, :string, "Description for customs declarations", optional: true
    param :declared_unit_cost_override, :number, "Override declared unit cost", optional: true
    param :average_po_cost, :number, "Average purchase order cost", optional: true
  end
  def update
    sku = Warehouse::SKU.find(params[:sku_id])
    sku.update!(params.permit(
      :name, :description, :enabled, :ai_enabled, :category,
      :country_of_origin, :hs_code, :customs_description,
      :declared_unit_cost_override, :average_po_cost
    ))
    @sku = sku
    load_sku_associations
    render :show
  end

  tool "List all SKUs with current stock levels", access: :read do
    param :page, :integer, "Page number", optional: true
  end
  def inventory
    @skus = paginate(Warehouse::SKU.in_inventory.order(:name))
  end

  tool "List SKUs that are backordered (negative stock)", access: :read
  def backordered
    @skus = Warehouse::SKU.backordered.order(:name)
  end

  private

  def load_sku_with_associations
    @sku = Warehouse::SKU.find(params[:sku_id])
    load_sku_associations
  end

  def load_sku_associations
    @recent_orders = Warehouse::Order.joins(:line_items)
      .where(warehouse_line_items: { sku_id: @sku.id })
      .distinct.order(created_at: :desc).limit(10)

    @outstanding_pos = Warehouse::PurchaseOrder.joins(:line_items)
      .where(warehouse_purchase_order_line_items: { sku_id: @sku.id })
      .where.not(status: "completed")
      .distinct.order(created_at: :desc)
  end
end
