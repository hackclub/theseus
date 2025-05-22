module API
  module V1
    class TagsController < ApplicationController
      # skip_before_action :authenticate!

      def index
        @tags = ::ApplicationController.helpers.available_tags
      end

      def show
        @tag = params[:id]

        letter_query = Letter.with_any_tags([@tag]).where(aasm_state: [:mailed, :received])
        wh_order_query = Warehouse::Order.with_any_tags([@tag]).where.not(aasm_state: [:draft, :errored])

        if letter_query.none? && wh_order_query.none?
          render json: { error: "no letters or warehouse orders found for tag #{@tag}...?" }, status: :not_found
          return
        end

        cache_key = "api/v1/tags/#{@tag}"
        cache_options = params[:no_cache] ? { force: true } : { expires_in: 5.minutes }

        cached_data = Rails.cache.fetch(cache_key, cache_options) do
          {
            letter_count: letter_query.count,
            letter_postage_cost: letter_query.sum(:postage),
            warehouse_order_count: wh_order_query.count,
            warehouse_order_postage_cost: wh_order_query.sum(:postage_cost),
            warehouse_order_labor_cost: wh_order_query.sum(:labor_cost),
            warehouse_order_contents_cost: wh_order_query.sum(:contents_cost),
            warehouse_order_total_cost: wh_order_query.sum(:postage_cost) + wh_order_query.sum(:labor_cost) + wh_order_query.sum(:contents_cost),
          }
        end

        @letter_count = cached_data[:letter_count]
        @letter_postage_cost = cached_data[:letter_postage_cost]
        @warehouse_order_count = cached_data[:warehouse_order_count]
        @warehouse_order_postage_cost = cached_data[:warehouse_order_postage_cost]
        @warehouse_order_labor_cost = cached_data[:warehouse_order_labor_cost]
        @warehouse_order_contents_cost = cached_data[:warehouse_order_contents_cost]
        @warehouse_order_total_cost = cached_data[:warehouse_order_total_cost]
      end

      def letters
        @letters = Letter.with_any_tags(params[:id])
      end
    end
  end
end
