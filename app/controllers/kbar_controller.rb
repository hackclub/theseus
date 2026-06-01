# frozen_string_literal: true

class KbarController < ApplicationController
  skip_after_action :verify_authorized

  def search
    q = params[:q].to_s.strip
    scope = params[:scope]

    results = if q.include?("!")
      search_public_id(q)
    elsif scope.present?
      search_scope(q, scope)
    else
      []
    end

    render json: results
  end

  private

  def search_public_id(q)
    prefix = q.split("!").first&.downcase
    clazzes = ActiveRecord::Base.descendants.select { |c| c.included_modules.include?(PublicIdentifiable) }
    clazz = clazzes.find { |c| c.public_id_prefix == prefix }
    return [] unless clazz

    record = clazz.find_by_public_id(q)
    return [] unless record

    [{ label: record_label(record), sublabel: record.public_id, path: url_for(record) }]
  rescue => e
    Rails.logger.warn("kbar public_id lookup failed: #{e.message}")
    []
  end

  def search_scope(q, scope)
    return [] if q.length < 2

    case scope
    when "letters" then search_letters(q)
    when "orders" then search_orders(q)
    else []
    end
  end

  def search_letters(q)
    letters = if q.match?(/\A\d+\z/)
      Letter.where(id: q).limit(8)
    else
      Letter.search(q).limit(8)
    end

    letters.includes(:address, :user).map do |l|
      addr = l.address
      name = addr ? [addr.first_name, addr.last_name].compact_blank.join(" ") : nil
      title = l.user_facing_title.presence

      sublabel = [name, title, l.aasm_state&.humanize].compact_blank.join(" · ")

      { label: "Letter ##{l.id}", sublabel:, path: letter_path(l) }
    end
  end

  def search_orders(q)
    orders = if q.match?(/\A\d+\z/)
      Warehouse::Order.where(id: q).or(Warehouse::Order.where(hc_id: q)).limit(8)
    elsif q.match?(/\A[A-Z0-9]{10,}\z/i)
      Warehouse::Order.where(tracking_number: q).limit(8)
    else
      Warehouse::Order.search(q).limit(8)
    end

    orders.includes(:address, :user).map do |o|
      addr = o.address
      name = addr ? [addr.first_name, addr.last_name].compact_blank.join(" ") : nil
      tracking = o.tracking_number.presence

      sublabel = [name, tracking, o.aasm_state&.humanize].compact_blank.join(" · ")

      { label: "Order ##{o.hc_id || o.id}", sublabel:, path: warehouse_order_path(o) }
    end
  end

  def record_label(record)
    case record
    when Letter then "Letter ##{record.id}"
    when Batch then "Batch ##{record.id}"
    when Warehouse::Order then "Order ##{record.hc_id || record.id}"
    when Warehouse::Template then record.name
    when User then record.username
    else "#{record.class.name.demodulize} ##{record.id}"
    end
  end
end
