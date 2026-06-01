# frozen_string_literal: true

class Components::Shared::StatusBadge < Components::Base
  def initialize(status:, type: :batch)
    @status = status
    @type = type
  end

  def view_template
    render(Primer::Beta::Label.new(
      scheme: scheme_for_status,
      size: :medium
    )) { text_for_status }
  end

  private

  def scheme_for_status
    case [@type, @status.to_s]
    when [:batch, 'awaiting_field_mapping'] then :attention
    when [:batch, 'fields_mapped'] then :accent
    when [:batch, 'processed'] then :success
    when [:letter, 'queued'] then :secondary
    when [:letter, 'pending'] then :attention
    when [:letter, 'printed'] then :accent
    when [:letter, 'mailed'], [:letter, 'received'] then :success
    when [:letter, 'canceled'], [:letter, 'failed'] then :danger
    else :secondary
    end
  end

  def text_for_status
    @status.to_s.humanize
  end
end
