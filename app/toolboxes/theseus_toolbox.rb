# Agent-facing affordances — orientation, lookup, overview.
# This toolbox is named "theseus" so tools are theseus_whoami, theseus_dashboard, etc.
class TheseusToolbox < ApplicationToolbox
  tool "Who am I? Returns the current user's identity, permissions, defaults, and what I can do.", access: :read do
  end
  def whoami
    user = current_user
    halt error: "Not authenticated" unless user

    render json: {
      id: user.id,
      username: user.username,
      email: user.email,
      permissions: {
        admin: user.admin?,
        warehouse_czar: user.warehouse_czar?,
        can_warehouse: user.can_warehouse?,
        can_use_indicia: user.can_use_indicia?,
        can_impersonate_public: user.can_impersonate_public?
      },
      defaults: {
        home_return_address: user.home_return_address&.then { |ra|
          { id: ra.id, name: ra.name, location: ra.location }
        },
        home_mailer_id: user.home_mid&.then { |mid|
          { id: mid.id, name: mid.name, mid: mid.mid }
        }
      },
      counts: {
        letters: user.letters.count,
        warehouse_orders: user.warehouse_orders.count,
        letter_queues: user.letter_queues.count,
        return_addresses: user.return_addresses.count,
        billing_profiles: user.billing_profiles.count
      }
    }
  end

  tool "Dashboard overview — what needs attention right now?", access: :read do
  end
  def dashboard
    user = current_user
    halt error: "Not authenticated" unless user

    data = { your_items: {} }

    # Your pending letters
    pending_letters = user.letters.where(aasm_state: "pending").count
    printed_letters = user.letters.where(aasm_state: "printed").count
    data[:your_items][:letters] = {
      pending: pending_letters,
      printed: printed_letters,
      actionable: pending_letters + printed_letters
    }

    # Your draft warehouse orders
    if user.can_warehouse? || user.admin?
      draft_orders = user.warehouse_orders.where(aasm_state: "draft").count
      dispatched_orders = user.warehouse_orders.where(aasm_state: "dispatched").count
      data[:your_items][:warehouse_orders] = {
        draft: draft_orders,
        dispatched: dispatched_orders
      }
    end

    # Warehouse czar: POs awaiting review
    if user.warehouse_czar? || user.admin?
      submitted_pos = Warehouse::PurchaseOrder.where(status: "submitted").count
      approved_pos = Warehouse::PurchaseOrder.where(status: "approved").count
      blocked_pos = Warehouse::PurchaseOrder.where(status: "approved")
        .select { |po| !po.all_skus_resolved? }.count

      data[:warehouse_review] = {
        pos_awaiting_approval: submitted_pos,
        pos_approved_pending_dispatch: approved_pos,
        pos_blocked_on_skus: blocked_pos
      }
    end

    # Admin: system overview
    if user.admin?
      data[:system] = {
        backordered_skus: Warehouse::SKU.backordered.count,
        total_users: User.count,
        letters_mailed_today: Letter.where("mailed_at >= ?", Time.current.beginning_of_day).count,
        orders_dispatched_today: Warehouse::Order.where("dispatched_at >= ?", Time.current.beginning_of_day).count
      }
    end

    render json: data
  end

  tool "Look up any theseus ID — public IDs (ltr!xxx, pkg!xxx, ind!xxx), hackapost IDs, tracking numbers, or plain search.", access: :read do
    param :id, :string, "Any identifier: public ID (ltr!xxx), hackapost!/xxx, tracking number, or search query"
  end
  def lookup
    q = params[:id].to_s.strip
    halt error: "Give me something to look up" if q.blank?

    resolver = PublicIdResolver.new(q)
    found = resolver.resolve

    if found && authorized_to_see?(found.record)
      render json: format_result(found)
    else
      # Fall back to search (scoped to user's accessible records)
      search_results = resolver.search.select { |r| authorized_to_see?(r.record) }
      if search_results.any?
        render json: { matches: search_results.map { |r| format_result(r) } }
      else
        render_error "Nothing found for \"#{q}\""
      end
    end
  end

  private

  # Check if the current user should see this record, mirroring Pundit policies.
  def authorized_to_see?(record)
    case record
    when Letter
      LetterPolicy.new(current_user, record).show?
    when Warehouse::Order
      can_warehouse?
    when Warehouse::PurchaseOrder
      can_warehouse?
    when USPS::Indicium
      admin?
    when Warehouse::SKU
      can_warehouse?
    when User
      admin? || record == current_user
    else
      true
    end
  end

  def format_result(result)
    record = result.record
    base = { type: result.type }

    case record
    when Letter
      base.merge(
        id: record.public_id,
        title: record.display_name,
        state: record.aasm_state,
        hint: "Use letters_show for full details"
      )
    when Warehouse::Order
      base.merge(
        id: record.hc_id,
        title: record.user_facing_title,
        state: record.aasm_state,
        tracking: record.tracking_number,
        hint: "Use warehouse_orders_show for full details"
      )
    when USPS::Indicium
      base.merge(
        id: record.public_id,
        hint: "Use postage_indicium_info for full details"
      )
    when Warehouse::PurchaseOrder
      base.merge(
        id: record.id,
        supplier: record.supplier_name,
        status: record.status,
        hint: "Use purchase_orders_show for full details"
      )
    when User
      base.merge(
        id: record.id,
        username: record.username,
        hint: "Use admin_users_show for full details"
      )
    else
      if record.respond_to?(:public_id)
        base.merge(id: record.public_id)
      else
        base.merge(id: record.id)
      end
    end
  end
end
