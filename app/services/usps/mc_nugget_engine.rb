module USPS
  class McNuggetEngine
    class << self
      FIXED_STAMPS = [
        { value: 0.28, name: "Additional Ounce" },
        { value: 1.00, name: "$1" },
      ].freeze

      UNCOMMON_STAMPS = [
        { value: 0.40, name: "$0.40" },
        { value: 0.10, name: "$0.10" },
        { value: 0.05, name: "$0.05" },
        { value: 0.04, name: "$0.04" },
        { value: 0.03, name: "$0.03" },
        { value: 0.02, name: "$0.02" },
        { value: 0.01, name: "$0.01" },
      ].freeze

      def common_stamps
        [
          { value: forever_stamp_value, name: "Forever" },
          { value: global_forever_value, name: "Global Forever" },
          { value: nonmachinable_stamp_value, name: "Non-machinable" },
          *FIXED_STAMPS,
        ]
      end

      def forever_stamp_value
        USPS::PricingEngine.domestic_stamp_price(:letter, 1.0)
      end

      def global_forever_value
        USPS::PricingEngine.fcmi_price(:letter, 1.0, "CA")
      end

      def nonmachinable_stamp_value
        USPS::PricingEngine.domestic_stamp_price(:letter, 1.0, true)
      end

      def find_stamp_combination(amount)
        return {} unless amount

        remaining = amount.round(2)
        combination = []

        if remaining == remaining.floor
          count = remaining.floor
          return [{ name: "$1 stamp", count: count, value: 1.00 }] if count > 0
        end

        all_stamps = (common_stamps + UNCOMMON_STAMPS).sort_by { |s| -s[:value] }

        all_stamps.each do |stamp|
          next if stamp[:value] > remaining
          count = (remaining / stamp[:value]).floor
          if count > 0
            count.times { combination << stamp }
            remaining = (remaining - (stamp[:value] * count)).round(2)
          end
        end

        return nil if remaining > 0

        grouped = combination.group_by { |s| s[:name] }
        grouped.map do |name, stamps|
          { name: "#{name} stamp", count: stamps.count, value: stamps.first[:value] }
        end.sort_by { |s| -s[:count] }
      end

      def find_optimal_stamp_combination(amount)
        return {} unless amount

        remaining = amount.round(2)
        all_stamps = (common_stamps + UNCOMMON_STAMPS).sort_by { |s| -s[:value] }
        memo = {}

        combination = min_stamps(remaining, all_stamps, memo)
        return nil if combination.nil?

        grouped = combination.group_by { |s| s[:name] }
        grouped.map do |name, stamps|
          { name: "#{name} stamp", count: stamps.count, value: stamps.first[:value] }
        end.sort_by { |s| -s[:count] }
      end

      private

      def min_stamps(amount, stamps, memo)
        return [] if amount == 0
        return nil if amount < 0
        return memo[amount] if memo.key?(amount)

        best_combination = nil
        min_count = Float::INFINITY

        stamps.each do |stamp|
          next if stamp[:value] > amount

          sub = min_stamps((amount - stamp[:value]).round(2), stamps, memo)
          if sub
            current = [stamp] + sub
            if current.size < min_count
              min_count = current.size
              best_combination = current
            end
          end
        end

        memo[amount] = best_combination
      end
    end
  end
end
