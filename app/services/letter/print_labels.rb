# frozen_string_literal: true

# Generate a PDF of labels for a subset of letters in a batch.
# Returns the rendered PDF data.
class Letter::PrintLabels
  attr_reader :batch, :letters

  def initialize(batch:, letter_ids: nil, count: 100)
    @batch = batch
    @letters = resolve_letters(letter_ids, count)
  end

  def call
    raise ArgumentError, "No letters to print." if letters.none?

    loaded = letters.includes(:address, :usps_indicium, :usps_mailer_id, :return_address)
    template_cycle = (batch.process_options || {})["template_cycle"]
    template_cycle = [ SnailMail::PhlexService.templates_for_size(:standard).first ].compact if template_cycle.blank?

    pdf = SnailMail::PhlexService.generate_batch_labels(loaded, template_cycle: template_cycle)
    batch.audit!(:print_subset, count: loaded.size, reprint: @reprint)

    { pdf_data: pdf.render, count: loaded.size, letter_ids: loaded.pluck(:id) }
  end

  private

  def resolve_letters(letter_ids, count)
    if letter_ids.present?
      @reprint = true
      batch.letters.where(id: letter_ids)
    else
      @reprint = false
      batch.letters.where(printed_at: nil).order(:id).limit(count.to_i.clamp(1, 5000))
    end
  end
end
