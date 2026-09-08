class WarehouseTemplatesToolbox < ApplicationToolbox
  before_action :require_warehouse!
  before_action :set_template, except: [:list]

  default_param :template_id, :string, "Template ID (e.g. wot_...)", except: [:list]

  tool "List warehouse templates (shared + your own)", access: :read do
    param :page, :integer, "Page number", optional: true
  end
  def list
    @templates = paginate(
      Warehouse::Template
        .where(public: true)
        .or(Warehouse::Template.where(user: current_user))
        .includes(line_items: :sku)
        .order(updated_at: :desc)
    )
  end

  tool "Show a warehouse template with full line item details", access: :read
  def show
    @template = @template.tap { |t| t.line_items.includes(:sku).load }
  end

  private

  def set_template
    @template = Warehouse::Template.find_by_public_id!(params[:template_id])
    unless @template.public? || @template.user == current_user || admin?
      halt error: "Template not found"
    end
  end
end
