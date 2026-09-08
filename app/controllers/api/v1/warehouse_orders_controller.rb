module API
  module V1
    class WarehouseOrdersController < ApplicationController
      include AddressParameterParsing

      before_action :set_warehouse_order, only: [:show]

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "Warehouse order not found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: {
          error: "Validation failed",
          details: e.record.errors.full_messages,
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
        address = parse_address_from_params(permit_address_params)
        @warehouse_order = Warehouse::Order.from_template(@template, warehouse_order_params.merge(
          address:, user: current_user, billing_profile: resolve_billing_profile,
        ))
        authorize @warehouse_order

        # Build additional line items from contents if provided
        if params[:contents].present?
          contents_params.each do |content_item|
            sku = Warehouse::SKU.find_by(sku: content_item[:sku])
            unless sku
              render json: { error: "SKU not found: #{content_item[:sku]}" }, status: :unprocessable_entity
              return
            end
            @warehouse_order.line_items.build(
              sku: sku,
              quantity: content_item[:quantity],
            )
          end
        end

        address.save!
        @warehouse_order.save!
        @warehouse_order.dispatch!
        render :show, status: :created
      end

      def create
        address = parse_address_from_params(permit_address_params)
        @warehouse_order = Warehouse::Order.new(warehouse_order_params.merge(
          address:, user: current_user, billing_profile: resolve_billing_profile,
        ))
        authorize @warehouse_order
        address.save!

        # Build line items from contents
        contents_params.each do |content_item|
          sku = Warehouse::SKU.find_by(sku: content_item[:sku])
          unless sku
            render json: { error: "SKU not found: #{content_item[:sku]}" }, status: :unprocessable_entity
            return
          end
          @warehouse_order.line_items.build(
            sku: sku,
            quantity: content_item[:quantity],
          )
        end

        @warehouse_order.save!
        @warehouse_order.dispatch!
        render :show, status: :created
      end

      private

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
        if params[:billing_profile_id].present?
          BillingProfile.find(params[:billing_profile_id])
        else
          current_token.billing_profile
        end
      end

      def contents_params
        return [] unless params[:contents].present?

        params.expect(contents: [[:sku, :quantity]]).map.with_index do |content_item, index|
          content_item.tap do |cp|
            raise ActionController::ParameterMissing.new([:contents, index, :sku]) unless cp[:sku].present?
            raise ActionController::ParameterMissing.new([:contents, index, :quantity]) unless cp[:quantity].present?
          end
        end
      end
    end
  end
end
