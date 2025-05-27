class TagsController < ApplicationController
  skip_after_action :verify_authorized
  # GET /tags or /tags.json
  def index
    @common_tags = CommonTag.all

    @tags = Rails.cache.fetch "tags_list" do
      warehouse_order_tags = Warehouse::Order.all_tags
      letter_tags = Letter.all_tags

      (warehouse_order_tags + letter_tags).uniq.compact_blank - @common_tags.map(&:tag)
    end
  end

  # GET /tags/1 or /tags/1.json
  def show
    tag = params[:id]
    time_period = params[:time_period] || "all_time"
    year = params[:year]&.to_i || Time.current.year
    month = params[:month]&.to_i

    # Base queries
    letter_query = Letter.with_any_tags([tag]).where.not(aasm_state: "queued")
    wh_order_query = Warehouse::Order.with_any_tags([tag])

    # Apply time period filter
    case time_period
    when "ytd"
      start_date = Date.new(year, 1, 1)
      letter_query = letter_query.where("created_at >= ?", start_date)
      wh_order_query = wh_order_query.where("created_at >= ?", start_date)
    when "month"
      if month.present?
        start_date = Date.new(year, month, 1)
        end_date = start_date.end_of_month
        letter_query = letter_query.where(created_at: start_date..end_date)
        wh_order_query = wh_order_query.where(created_at: start_date..end_date)
      end
    when "last_week"
      letter_query = letter_query.where("created_at >= ?", 1.week.ago)
      wh_order_query = wh_order_query.where("created_at >= ?", 1.week.ago)
    when "last_month"
      letter_query = letter_query.where("created_at >= ?", 1.month.ago)
      wh_order_query = wh_order_query.where("created_at >= ?", 1.month.ago)
    when "last_year"
      letter_query = letter_query.where("created_at >= ?", 1.year.ago)
      wh_order_query = wh_order_query.where("created_at >= ?", 1.year.ago)
    end

    @letter_count = letter_query.count
    @letter_postage_cost = letter_query.sum(:postage)
    @warehouse_order_count = wh_order_query.count
    @warehouse_order_postage_cost = wh_order_query.sum(:postage_cost)
    @warehouse_order_labor_cost = wh_order_query.sum(:labor_cost)
    @warehouse_order_contents_cost = wh_order_query.sum(:contents_cost)
    @warehouse_order_total_cost = @warehouse_order_postage_cost + @warehouse_order_labor_cost + @warehouse_order_contents_cost

    @tag = tag
    @time_period = time_period
    @year = year
    @month = month
    @years = (2020..Time.current.year).to_a.reverse
    @months = (1..12).map { |m| [Date::MONTHNAMES[m], m] }
  end

  def refresh
    Rails.cache.delete("tags_list")
    flash[:success] = "refreshed!"
    redirect_to tags_path
  end
end
