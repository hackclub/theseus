# frozen_string_literal: true

class DashboardStats
  def initialize(user: nil)
    @user = user
  end

  # === ACTION ITEMS (needs your attention) ===

  def orders_to_dispatch
    @orders_to_dispatch ||= Warehouse::Order.where(aasm_state: "draft").count
  end

  def letters_to_print
    @letters_to_print ||= Letter.where(aasm_state: "pending").count
  end

  def letters_to_mail
    @letters_to_mail ||= Letter.where(aasm_state: "printed").count
  end

  def open_letter_batches
    @open_letter_batches ||= Letter::Batch.where(aasm_state: "open").count
  end

  def my_queued_letters
    return 0 unless @user
    @my_queued_letters ||= Letter.joins(:queue)
                                  .where(letter_queues: { user_id: @user.id })
                                  .where(aasm_state: "queued")
                                  .count
  end

  def my_queue_count
    return 0 unless @user
    @my_queue_count ||= Letter::Queue.where(user_id: @user.id).count
  end

  # === GLOBAL STATS (activity/throughput) ===

  def orders_in_transit
    @orders_in_transit ||= Warehouse::Order.where(aasm_state: "dispatched").count
  end

  def orders_shipped_this_week
    @orders_shipped_this_week ||= Warehouse::Order.where(aasm_state: "mailed")
                                                   .where("mailed_at >= ?", 1.week.ago)
                                                   .count
  end

  def letters_mailed_this_week
    @letters_mailed_this_week ||= Letter.where(aasm_state: "mailed")
                                        .where("mailed_at >= ?", 1.week.ago)
                                        .count
  end

  def total_letters_this_month
    @total_letters_this_month ||= Letter.where("created_at >= ?", 1.month.ago).count
  end

  def [](key)
    public_send(key) if respond_to?(key)
  end
end
