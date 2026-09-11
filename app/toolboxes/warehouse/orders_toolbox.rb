# frozen_string_literal: true

module Warehouse
  class OrdersToolbox < ApplicationToolbox
    include BillingProfileResolvable
    before_action :require_warehouse!
    before_action :set_order, except: [ :search, :create, :create_from_template ]
    before_action :require_owner_or_admin!, only: [ :update, :send_to_warehouse, :cancel, :destroy ]

    default_param :order_id, :string, "Order ID (e.g. pkg!...)", except: [ :search, :create, :create_from_template ]

    tool "Search warehouse package orders by keyword with optional state filter. Returns paginated list with recipient, status, and tracking", access: :read do
      param :query, :string, "Search term (matches order ID, recipient email, title, tags, address name)", optional: true
      param :state, :string, "Filter by state", optional: true, enum: %w[draft dispatched mailed canceled]
      param :page, :integer, "Page number", optional: true
    end
    def search
      scope = policy_scope(Warehouse::Order).includes(:address, :user, line_items: :sku).order(created_at: :desc)
      scope = scope.where(aasm_state: params[:state]) if params[:state].present?
      scope = scope.search(params[:query]) if params[:query].present?
      @orders = paginate(scope)
    end

    tool "Show full details for a warehouse package order including line items, shipping address, costs, and tracking", access: :read
    def show
      @order = @order.tap { |o| o.line_items.includes(:sku).load }
    end

    tool "Create a new warehouse package order for physical shipment via the fulfillment warehouse", access: :write do
      param :user_facing_title, :string, "Title shown to recipient"
      param :user_facing_description, :string, "Description shown to recipient", optional: true
      param :internal_notes, :string, "Internal notes (not shown to recipient)", optional: true
      param :recipient_email, :string, "Recipient email address"
      param :notify_on_dispatch, :boolean, "Email recipient when order ships", optional: true
      param :billing_profile_id, :string, "Billing profile for charging shipment costs (use postage_billing_profiles to find)", optional: true
      param :tags, [ :string ], "Tags for the order", optional: true
      param :line_items, [ :object ], "Items to ship, each with a sku_id (integer) and quantity (integer)"
      param :address, :object, "Shipping address — {first_name, last_name, line_1, line_2, city, state, postal_code, country, phone_number, email}"
    end
    def create
      billing_profile = resolve_billing_profile(params[:billing_profile_id])

      @order = Warehouse::Order.new(
        order_params.merge(
          user: current_user,
          billing_profile: billing_profile,
        ),
      )
      @order.save!
      render :show
      suggests :send_to_warehouse, "Send this draft to the warehouse when ready"
    end

    tool "Create a warehouse package order from a saved template of pre-configured items", access: :write do
      param :template_id, :string, "Template ID (e.g. wot!...)"
      param :recipient_email, :string, "Recipient email address"
      param :notify_on_dispatch, :boolean, "Email recipient when order ships", optional: true
      param :billing_profile_id, :string, "Billing profile for charging shipment costs (use postage_billing_profiles to find)", optional: true
      param :tags, [ :string ], "Tags for the order", optional: true
      param :address, :object, "Shipping address — {first_name, last_name, line_1, line_2, city, state, postal_code, country, phone_number, email}"
    end
    def create_from_template
      template = Warehouse::Template.find_by_public_id!(params[:template_id])
      unless template.public? || template.user == current_user || admin?
        halt error: "Template not found"
      end
      billing_profile = resolve_billing_profile(params[:billing_profile_id])

      attrs = {
        recipient_email: params[:recipient_email],
        notify_on_dispatch: params[:notify_on_dispatch],
        tags: params[:tags] || [],
        user: current_user,
        billing_profile: billing_profile,
        address_attributes: params[:address]&.permit(
          :first_name, :last_name, :line_1, :line_2, :city, :state, :postal_code, :country, :phone_number, :email
        )&.to_h
      }.compact

      @order = Warehouse::Order.from_template(template, attrs)
      @order.save!
      render :show
      suggests :send_to_warehouse, "Send this draft to the warehouse when ready"
    end

    tool "Update a draft warehouse package order before dispatch", access: :write do
      param :user_facing_title, :string, "Title shown to recipient", optional: true
      param :user_facing_description, :string, "Description shown to recipient", optional: true
      param :internal_notes, :string, "Internal notes", optional: true
      param :recipient_email, :string, "Recipient email address", optional: true
      param :notify_on_dispatch, :boolean, "Email recipient when order ships", optional: true
      param :billing_profile_id, :string, "Billing profile for charging shipment costs (use postage_billing_profiles to find)", optional: true
      param :tags, [ :string ], "Tags for the order", optional: true
      param :line_items, [ :object ], "Line items — each: {id: integer (for update), sku_id: integer, quantity: integer, _destroy: boolean}", optional: true
      param :address, :object, "Shipping address fields to update", optional: true
    end
    def update
      billing_profile = resolve_billing_profile(params[:billing_profile_id])
      update_attrs = order_params
      update_attrs[:billing_profile] = billing_profile if params.key?(:billing_profile_id)

      @order.update!(update_attrs)
      render :show
    end

    tool "Dispatch a draft order to the fulfillment warehouse for physical shipping (draft → dispatched)", access: :write
    def send_to_warehouse
      halt error: "Order is not a draft" unless @order.draft?

      result = mcp_elicit(
        "Dispatch order #{@order.hc_id} to the warehouse?\n\n" \
        "Recipient: #{@order.address&.name_line}\n" \
        "Items: #{@order.line_items.includes(:sku).map { |li| "#{li.quantity}x #{li.sku.name}" }.join(", ")}\n" \
        "This will send the order to Zenventory for fulfillment.",
        schema: {
          type: "object",
          properties: { confirmed: { type: "boolean", description: "Yes, dispatch this order" } },
          required: [ "confirmed" ]
        }
      )
      halt error: "Dispatch cancelled" unless result["action"] == "accept" && result.dig("content", "confirmed")

      @order.dispatch!
      render :show
    end

    tool "Cancel a dispatched order at the fulfillment warehouse, not just locally (dispatched → canceled)", access: :write do
      param :reason, :string, "Reason for cancellation"
    end
    def cancel
      result = mcp_elicit(
        "Cancel order #{@order.hc_id}?\n\nReason: #{params[:reason]}\n\nThis will cancel the order in Zenventory.",
        schema: {
          type: "object",
          properties: { confirmed: { type: "boolean", description: "Yes, cancel this order" } },
          required: [ "confirmed" ]
        }
      )
      halt error: "Cancellation aborted" unless result["action"] == "accept" && result.dig("content", "confirmed")

      @order.cancel!(params[:reason])
      render :show
    end

    private

    def set_order
      @order = Warehouse::Order.find_by!(hc_id: params[:order_id])
    end

    def require_owner_or_admin!
      halt error: "Forbidden — you don't own this order" unless @order.user_id == current_user.id || admin?
    end


    def resolve_billing_profile(id_or_public_id)
      profile = find_billing_profile(id_or_public_id)
      halt error: "Billing profile not found or not yours" unless profile
      profile
    end

    def order_params
      attrs = params.permit(
        :user_facing_title, :user_facing_description, :internal_notes,
        :recipient_email, :notify_on_dispatch,
        tags: [],
      ).to_h

      if params[:line_items].present?
        attrs[:line_items_attributes] = params[:line_items].map { |li|
          li.permit(:id, :sku_id, :quantity, :_destroy).to_h
        }
      end

      if params[:address].present?
        attrs[:address_attributes] = params[:address].permit(
          :first_name, :last_name, :line_1, :line_2, :city, :state, :postal_code, :country, :phone_number, :email
        ).to_h
      end

      attrs
    end
  end
end
