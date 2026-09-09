class TagsToolbox < ApplicationToolbox
  tool "Search tags used to organize letters and warehouse orders by campaign or project. Returns distinct tag names with usage counts", access: :read do
    param :query, :string, "Filter tags by name (case-insensitive partial match)", optional: true
  end
  def search
    letter_tags = letter_tag_counts(params[:query])
    warehouse_tags = warehouse_tag_counts(params[:query])

    all_tag_names = (letter_tags.keys + warehouse_tags.keys).uniq.sort

    @tags = all_tag_names.map do |tag|
      {
        tag: tag,
        letter_count: letter_tags[tag] || 0,
        warehouse_order_count: warehouse_tags[tag] || 0,
        is_common: common_tag_names.include?(tag)
      }
    end
  end

  tool "Show detailed stats for a tag including counts broken down by state for both letters and warehouse orders", access: :read do
    param :tag, :string, "Tag name"
  end
  def show
    tag = params[:tag]

    letters = Letter.with_any_tags([ tag ])
    warehouse_orders = Warehouse::Order.with_any_tags([ tag ])

    @tag = tag
    @letter_total = letters.count
    @letters_by_state = letters.group(:aasm_state).count
    @warehouse_order_total = warehouse_orders.count
    @warehouse_orders_by_state = warehouse_orders.group(:aasm_state).count
    @is_common = common_tag_names.include?(tag)

    common = CommonTag.find_by(tag: tag)
    @implies_ysws = common&.implies_ysws || false
  end

  private

  def common_tag_names
    @common_tag_names ||= CommonTag.pluck(:tag)
  end

  def letter_tag_counts(query = nil)
    sql = "SELECT unnest(tags) AS tag, COUNT(*) AS cnt FROM letters GROUP BY tag"
    rows = ActiveRecord::Base.connection.select_all(sql)
    result = rows.each_with_object({}) { |r, h| h[r["tag"]] = r["cnt"] }
    return result unless query.present?

    pattern = query.downcase
    result.select { |tag, _| tag.downcase.include?(pattern) }
  end

  def warehouse_tag_counts(query = nil)
    sql = "SELECT unnest(tags) AS tag, COUNT(*) AS cnt FROM warehouse_orders GROUP BY tag"
    rows = ActiveRecord::Base.connection.select_all(sql)
    result = rows.each_with_object({}) { |r, h| h[r["tag"]] = r["cnt"] }
    return result unless query.present?

    pattern = query.downcase
    result.select { |tag, _| tag.downcase.include?(pattern) }
  end
end
