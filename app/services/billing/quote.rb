# frozen_string_literal: true

# Totals and a balance verdict over a ledgerable's billing_lines.
class Billing::Quote
  FLOOR_CENTS = 1_000

  Line = Struct.new(:category, :label, :when, :amount_cents, :count, keyword_init: true) do
    def now? = self.when == :now
    def later? = self.when == :later
    def known? = !amount_cents.nil?
  end

  attr_reader :lines

  def initialize(lines)
    @lines = Array(lines).compact.freeze
  end

  def empty? = lines.empty?
  def any? = !empty?
  def later? = lines.any?(&:later?)
  def now_cents = lines.select(&:now?).sum { |l| l.amount_cents.to_i }
  def later_cents = lines.select(&:later?).sum { |l| l.amount_cents.to_i }
  def count = lines.map { |l| l.count.to_i }.max || 1

  # => :unknown | :insufficient | :low | :ok
  def assess(balance_cents)
    return :unknown if balance_cents.nil?
    return :insufficient if balance_cents < now_cents
    remaining = balance_cents - now_cents
    return :low if remaining < later_cents || remaining < FLOOR_CENTS * [ count, 1 ].max
    :ok
  end
end
