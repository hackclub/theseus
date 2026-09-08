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
    result = PublicIdResolver.resolve(q)
    return [] unless result

    record = result.record
    # Re-check via policy_scope for authorization
    record = policy_scope(record.class).find_by(id: record.id)
    return [] unless record

    [{ label: record_label(record), sublabel: record.respond_to?(:public_id) ? record.public_id : record.id.to_s, path: url_for(record) }]
  rescue => e
    Rails.logger.warn("kbar public_id lookup failed: #{e.message}")
    []
  end

  def search_scope(q, scope)
    return [] if q.length < 2

    case scope
    when "letters" then search_letters(q)
    when "orders" then search_orders(q)
    when "users" then search_users(q)
    else []
    end
  end

  def search_letters(q)
    scope = policy_scope(Letter)
    letters = if q.match?(/\A\d+\z/)
      scope.where(id: q).limit(8)
    else
      scope.search(q).limit(8)
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
    scope = policy_scope(Warehouse::Order)
    orders = if q.match?(/\A\d+\z/)
      scope.where(id: q).or(scope.where(hc_id: q)).limit(8)
    elsif q.match?(/\A[A-Z0-9]{10,}\z/i)
      scope.where(tracking_number: q).limit(8)
    else
      scope.search(q).limit(8)
    end

    orders.includes(:address, :user).map do |o|
      addr = o.address
      name = addr ? [addr.first_name, addr.last_name].compact_blank.join(" ") : nil
      tracking = o.tracking_number.presence

      sublabel = [name, tracking, o.aasm_state&.humanize].compact_blank.join(" · ")

      { label: "Order ##{o.hc_id || o.id}", sublabel:, path: warehouse_order_path(o) }
    end
  end

  def search_users(q)
    return [] unless current_user&.admin?

    users = User.where("username ILIKE :q OR email ILIKE :q", q: "%#{q}%").order(:username).limit(8)

    users.map do |u|
      {
        label: u.username.presence || u.email,
        sublabel: [u.email, u.is_admin? ? "Admin" : nil].compact_blank.join(" · "),
        path: admin_user_path(u)
      }
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
