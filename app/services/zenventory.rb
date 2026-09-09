# frozen_string_literal: true

module FaradayMiddleware
  class ZenventoryErrorMiddleware < Faraday::Middleware
    def on_complete(env)
      unless env.response.success?
        Rails.logger.error("ZENV: #{env.response.body}")
        if env.response.body&.dig(:code) == "invalid_parameter"
          raise Zenventory::ZenventoryError, "invalid parameter: #{env.response.body.dig(:parameter)}"
        end
        raise Zenventory::ZenventoryError, env.response.body[:message] if env.response.body&.dig(:message)
        raise Zenventory::ZenventoryError, "not found :-(" if env.response.status == 404
        raise Zenventory::ZenventoryError, "you're trying to create an order that already exists!" if env.response.body == '{"code":"invalid_parameter","message":"Invalid value for parameter.","parameter":"orderNumber"}'
        raise Zenventory::ZenventoryError, "#{env.response.status}: #{env.response.body}"
      end
    end
  end
end

Faraday::Response.register_middleware zenventory_error: FaradayMiddleware::ZenventoryErrorMiddleware

class Zenventory
  class << self
    def order_by_hc_id(id)
      get_customer_orders(orderNumber: id, no_paginate: true).first
    end

    def get_customer_orders(params = {})
      paginated_get("customer-orders", :customerOrders, params)
    end

    def get_customer_order(id)
      response = conn.get("customer-orders/#{id}").body
      response
    end

    def create_customer_order(params = {})
      conn.post("customer-orders",
                saveAsDraft: !(ENV["SEND_REAL_ORDERS"] == "yeah"),
                **params).body
    end

    def update_customer_order(id, params = {})
      conn.put("customer-orders/#{id}",
               saveAsDraft: !(ENV["SEND_REAL_ORDERS"] == "yeah"),
               **params).body
    end

    def get_inventory(params = {})
      paginated_get("inventory", :inventory, params)
    end

    def get_kit_inventory(params = {})
      paginated_get("inventory/kits", :inventory, params)
    end

    def get_items(params = {})
      paginated_get("items", :items, params)
    end

    def get_item(id, include_units: false, include_bom: false)
      conn.get("items/#{id}", includeUnits: include_units, includeBom: include_bom).body
    end

    def create_item(params = {})
      conn.post("items", **params).body
    end

    def update_item(id, params = {})
      conn.put("items/#{id}", **params).body
    end

    def get_purchase_orders(params = {})
      paginated_get("purchase-orders", :purchaseOrders, params)
    end

    def get_purchase_order(id)
      conn.get("purchase-orders/#{id}").body
    end

    def create_purchase_order(params = {})
      conn.post("purchase-orders", **params).body
    end

    def draft_purchase_order(params = {})
      create_purchase_order(draft: true, **params)
    end

    def update_purchase_order(id, params = {})
      conn.put("purchase-orders/#{id}", **params).body
    end

    def finalize_purchase_order(id, params = {})
      update_purchase_order(id, draft: false, **params)
    end

    def close_purchase_order(id)
      conn.put("purchase-orders/#{id}/close").body
    end

    def get_suppliers
      get_purchase_orders.map { |po| po[:supplier] }.compact.uniq { |s| s[:id] }
    end

    def run_report(category, report_key, params = {})
      CSV.parse(
        conn.get("reports/#{category}/#{report_key}", csv: true, **params).body,
        headers: true,
        converters: %i[numeric date],
        header_converters: %i[downcase symbol],
      )&.map(&:to_h)
    end

    def cancel_customer_order(id, reason)
      resp = legacy_conn.put("customerorders/#{id}/cancel?reason=#{reason}").body
      raise ZenventoryError, "couldn't cancel!" unless resp[:success]
    end

    # ─── ･ ｡ﾟ☆: *.☽ .* :☆ﾟ. ───

    def conn
      raise "zenventory: no creds?" unless Rails.application.credentials.dig(:zenventory, :api_key) && Rails.application.credentials.dig(:zenventory, :api_secret)
      @conn ||= Faraday.new url: "https://app.zenventory.com/rest/" do |c|
        c.request :json
        c.request :authorization, :basic, Rails.application.credentials.dig(:zenventory, :api_key), Rails.application.credentials.dig(:zenventory, :api_secret)
        c.response :zenventory_error
        c.response :json, parser_options: { symbolize_names: true }
      end
    end

    def paginated_get(url, obj, params = {}, page_size: 100)
      no_paginate = params.delete :no_paginate
      page = 1
      data = []
      loop do
        response = conn.get(url, page:, perPage: page_size, **params).body
        data.concat(response[obj] || [])
        page += 1
        break if page > (response.dig(:meta, :totalPages) || 0) or no_paginate
      end
      data
    end

    def legacy_conn
      @legacy_conn ||= Faraday.new(url: "https://app.zenventory.com/services/rest") do |c|
        c.request :json
        c.response :zenventory_error
        c.response :json, parser_options: { symbolize_names: true }
        c.headers["SecureKey"] = Rails.application.credentials.dig(:zenventory, :legacy_secure_key) || (raise "zenv: no legacy secure key set!")
      end
    end
  end

  class ZenventoryError < StandardError; end
end
