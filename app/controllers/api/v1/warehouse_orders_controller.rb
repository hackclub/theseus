module API
  module V1
    class WarehouseOrdersController < ApplicationController
      include AddressParameterParsing

      before_action :set_warehouse_order, only: [ :show ]

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "Warehouse order not found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: {
          error: "Validation failed",
          details: e.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def show
        authorize @warehouse_order
      end

      def index
        @warehouse_orders = policy_scope(Warehouse::Order)
      end

      def from_template
        @template = Warehouse::Template.find_by_public_id!(params[:template_id])
        raise ActiveRecord::RecordNotFound unless @template.public? || @template.user == current_user || current_user.admin?
        billing_profile = resolve_billing_profile
        return if performed?

        address = parse_address_from_params(permit_address_params)
        return if address.nil?

        @warehouse_order = Warehouse::Order.from_template(@template, warehouse_order_params.merge(
          address:, user: current_user, billing_profile:,
        ))
        authorize @warehouse_order

        # Build additional line items from contents if provided
        return unless build_line_items(contents_params)

        save_order_with!(address)
        @warehouse_order.dispatch!
        render :show, status: :created
      end

      def create
        billing_profile = resolve_billing_profile
        return if performed?

        address = parse_address_from_params(permit_address_params)
        return if address.nil?

        @warehouse_order = Warehouse::Order.new(warehouse_order_params.merge(
          address:, user: current_user, billing_profile:,
        ))
        authorize @warehouse_order

        return unless build_line_items(contents_params)

        save_order_with!(address)
        @warehouse_order.dispatch!
        render :show, status: :created
      end

      private

      # The address and its order live and die together. Saving the address first left
      # one behind every time the order was rejected -- which went from rare to routine
      # once international orders started needing a phone number for customs.
      #
      # dispatch! stays outside: it talks to Zenventory over the network, and a remote
      # order we've rolled the local record back on is worse than no order at all.
      def save_order_with!(address)
        ActiveRecord::Base.transaction do
          address.save!
          @warehouse_order.save!
        end
      end

      # Returns false (having rendered an error) if any SKU is unknown.
      def build_line_items(contents)
        contents.each do |content_item|
          sku = Warehouse::SKU.find_by(sku: content_item[:sku])
          unless sku
            render json: { error: "SKU not found: #{content_item[:sku]}" }, status: :unprocessable_entity
            return false
          end
          @warehouse_order.line_items.build(
            sku: sku,
            quantity: content_item[:quantity],
          )
        end
        true
      end

      def set_warehouse_order
        @warehouse_order = policy_scope(Warehouse::Order).find_by!(hc_id: params[:id])
      end

      def warehouse_order_params
        params.require(:warehouse_order).permit(
          :recipient_email,
          :user_facing_title,
          :idempotency_key,
          metadata: {},
          tags: [],
        ).tap do |wp|
          wp.require(:recipient_email)
          wp.require(:tags)
          raise ActionController::ParameterMissing.new(:tags) if wp[:tags].blank? || wp[:tags].empty?
        end
      end

      # Per-request billing_profile_id overrides the API key's default
      def resolve_billing_profile
        profile = if params[:billing_profile_id].present?
          # Accept public ID (bp!xxx) or numeric ID, scoped to current user
          id = params[:billing_profile_id]
          current_user.billing_profiles.find_by(id: id) ||
            BillingProfile.find_by_public_id(id)&.then { |p| p if p.user == current_user }
        else
          current_token.billing_profile
        end

        if params[:billing_profile_id].present? && profile.nil?
          render json: { error: "not_authorized", message: "Billing profile not found or not yours." }, status: :forbidden
          return nil
        end

        if profile.nil? && Flipper.enabled?(:require_billing_profile_2026_09_08)
          render json: {
            error: "billing_profile_required",
            message: "A billing profile is required for warehouse orders. Set a default on your API key or pass billing_profile_id per request."
          }, status: :unprocessable_entity
          return nil
        end

        profile
      end

      def contents_params
        return [] unless params[:contents].present?

        params.expect(contents: [ [ :sku, :quantity ] ]).map.with_index do |content_item, index|
          content_item.tap do |cp|
            raise ActionController::ParameterMissing.new([ :contents, index, :sku ]) unless cp[:sku].present?
            raise ActionController::ParameterMissing.new([ :contents, index, :quantity ]) unless cp[:quantity].present?
          end
        end
      end
    end
  end
end
