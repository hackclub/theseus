# frozen_string_literal: true

# HCB memos: "[theseus] indicia bat_x9y8 $412.30 (T#4799) · batch postage"
module Billing::Memo
  MAX_LINES = 8
  PREFIX = "[theseus]"

  def self.ref(ledgerable)
    case ledgerable
    when Warehouse::Order then ledgerable.hc_id.presence || ledgerable.public_id
    when USPS::Indicium then ledgerable.letter&.public_id || ledgerable.public_id
    when Batch then ledgerable.public_id
    when nil then "?"
    else
      ledgerable.try(:public_id) || "#{ledgerable.class.name.demodulize.downcase}##{ledgerable.id}"
    end
  end

  def self.money(cents) = ActiveSupport::NumberHelper.number_to_currency(cents.abs / 100.0)

  def self.charge(entries, note: nil)
    entries = entries.to_a
    lines = entries.first(MAX_LINES).map { |e| "#{e.category} #{ref(e.ledgerable)} #{money(e.amount_cents)} (T##{e.id})" }
    lines << "and #{entries.size - MAX_LINES} more" if entries.size > MAX_LINES
    compose(lines.join(", "), note)
  end

  def self.credit(credit_entry, original, note: nil)
    compose("refund #{original.category} #{ref(original.ledgerable)} #{money(credit_entry.amount_cents)} (T##{credit_entry.id} reverses T##{original.id})", note)
  end

  def self.compose(body, note)
    [ PREFIX, body, note.presence && "· #{note.strip}" ].compact.join(" ")
  end
  private_class_method :compose
end
