# Resolves any theseus identifier to a record.
#
# Handles:
#   - Public IDs: "ltr!abc", "pkg!xyz", "ind!def"
#   - Hackapost IDs: "hackapost!/abc", "dev!/123"
#   - Tracking numbers: "94346501061..."
#   - Falls back to pg_search on letters + warehouse orders
#
# Used by PublicIdsController, KbarController, and TheseusToolbox.
class PublicIdResolver
  Result = Struct.new(:record, :type, keyword_init: true)

  def self.resolve(query)
    new(query).resolve
  end

  def initialize(query)
    @query = query.to_s.strip
  end

  def resolve
    return nil if @query.blank?

    by_public_id || by_hackapost || by_tracking_number
  end

  # Just the public_id → record part (no search fallback).
  def resolve_exact
    return nil if @query.blank?

    by_public_id || by_hackapost || by_tracking_number
  end

  def search
    return [] if @query.blank?

    results = []
    results.concat(Letter.search(@query).limit(5).map { |r| Result.new(record: r, type: "Letter") }) rescue nil
    results.concat(Warehouse::Order.search(@query).limit(5).map { |r| Result.new(record: r, type: "Warehouse::Order") }) rescue nil
    results
  end

  private

  def by_public_id
    return nil unless @query.include?("!")
    prefix = @query.split("!").first&.downcase
    return nil if %w[hackapost dev].include?(prefix)

    klass = public_id_class_for(prefix)
    return nil unless klass

    record = klass.find_by_public_id(@query)
    record ? Result.new(record: record, type: klass.name) : nil
  rescue => e
    Rails.logger.warn("PublicIdResolver: #{e.message}")
    nil
  end

  def by_hackapost
    return nil unless @query.match?(/\A(hackapost|dev)[!\/]/i)
    hashid_or_id = @query.split(/[!\/]/, 2).last

    indicium = if @query.downcase.start_with?("dev")
      USPS::Indicium.find_by(id: hashid_or_id)
    else
      USPS::Indicium.find_by_hashid(hashid_or_id)
    end

    indicium ? Result.new(record: indicium, type: "USPS::Indicium") : nil
  rescue => e
    Rails.logger.warn("PublicIdResolver hackapost: #{e.message}")
    nil
  end

  def by_tracking_number
    return nil unless @query.match?(/\A[A-Z0-9]{10,}\z/i)

    order = Warehouse::Order.find_by(tracking_number: @query)
    order ? Result.new(record: order, type: "Warehouse::Order") : nil
  end

  def public_id_class_for(prefix)
    @public_id_classes ||= ActiveRecord::Base.descendants
      .select { |c| c.included_modules.include?(PublicIdentifiable) }

    @public_id_classes.find { |c| c.public_id_prefix == prefix }
  end
end
