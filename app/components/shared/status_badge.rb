# frozen_string_literal: true

class Components::Shared::StatusBadge < Components::Base
  def initialize(status:, type: :batch)
    @status = status
    @type = type
  end

  def view_template
    span("is-": "badge", "variant-": variant_for_status) { text_for_status }
  end

  private

  def variant_for_status
    case [@type, @status.to_s]
    when [:batch, "awaiting_field_mapping"] then "yellow"
    when [:batch, "fields_mapped"] then "blue"
    when [:batch, "processed"] then "green"
    when [:letter, "queued"] then "background2"
    when [:letter, "pending"] then "yellow"
    when [:letter, "printed"] then "blue"
    when [:letter, "mailed"], [:letter, "received"] then "green"
    when [:letter, "canceled"], [:letter, "failed"] then "red"
    else "background2"
    end
  end

  def text_for_status
    @status.to_s.humanize
  end
end
