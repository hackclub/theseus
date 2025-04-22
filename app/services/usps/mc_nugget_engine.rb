module USPS
    class McNuggetEngine
        class << self
            # Common stamps that should be used first
            COMMON_STAMPS = [
                { value: 0.73, name: "Forever" },
                { value: 1.65, name: "Global Forever" },
                { value: 1.19, name: "Non-machinable" },
                { value: 0.28, name: "Additional Ounce" },
                { value: 1.00, name: "$1" }
            ].freeze

            # Less common stamps, ordered by value (largest first)
            UNCOMMON_STAMPS = [
                { value: 0.40, name: "$0.40" },
                { value: 0.10, name: "$0.10" },
                { value: 0.05, name: "$0.05" },
                { value: 0.04, name: "$0.04" },
                { value: 0.03, name: "$0.03" },
                { value: 0.02, name: "$0.02" },
                { value: 0.01, name: "$0.01" }
            ].freeze

            def find_stamp_combination(amount)
                return {} unless amount

                remaining = amount.round(2)
                combination = []

                # Special case: if amount is a whole dollar, prefer $1 stamps
                if remaining == remaining.floor
                    count = remaining.floor
                    return [ { name: "$1 stamp", count: count, value: 1.00 } ] if count > 0
                end

                # First try to use the largest possible stamp
                all_stamps = (COMMON_STAMPS + UNCOMMON_STAMPS).sort_by { |s| -s[:value] }

                all_stamps.each do |stamp|
                    next if stamp[:value] > remaining
                    count = (remaining / stamp[:value]).floor
                    if count > 0
                        count.times { combination << stamp }
                        remaining = (remaining - (stamp[:value] * count)).round(2)
                    end
                end

                # If we couldn't make exact change, return nil
                return nil if remaining > 0

                # Group and count the stamps, then sort by count (descending)
                grouped = combination.group_by { |s| s[:name] }
                result = grouped.map do |name, stamps|
                    { name: "#{name} stamp", count: stamps.count, value: stamps.first[:value] }
                end.sort_by { |s| -s[:count] }

                result
            end

            def find_optimal_stamp_combination(amount)
                return {} unless amount

                remaining = amount.round(2)
                all_stamps = (COMMON_STAMPS + UNCOMMON_STAMPS).sort_by { |s| -s[:value] }

                # Initialize memoization table
                memo = {}

                def self.min_stamps(amount, stamps, memo)
                    return [] if amount == 0
                    return nil if amount < 0

                    # Check if we've already computed this amount
                    return memo[amount] if memo.key?(amount)

                    best_combination = nil
                    min_count = Float::INFINITY

                    stamps.each do |stamp|
                        next if stamp[:value] > amount

                        # Try using this stamp
                        remaining = (amount - stamp[:value]).round(2)
                        sub_combination = min_stamps(remaining, stamps, memo)

                        if sub_combination
                            current_combination = [ stamp ] + sub_combination
                            if current_combination.size < min_count
                                min_count = current_combination.size
                                best_combination = current_combination
                            end
                        end
                    end

                    memo[amount] = best_combination
                    best_combination
                end

                combination = min_stamps(remaining, all_stamps, memo)

                return nil if combination.nil?

                # Group and count the stamps, then sort by count (descending)
                grouped = combination.group_by { |s| s[:name] }
                result = grouped.map do |name, stamps|
                    { name: "#{name} stamp", count: stamps.count, value: stamps.first[:value] }
                end.sort_by { |s| -s[:count] }

                result
            end
        end
    end
end
