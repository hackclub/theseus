module LettersHelper
  # Returns appropriate CSS classes for letter status badges based on the current state
  def letter_status_class(status)
    case status.to_s
    # when 'pending'
      # 'bg-warning-bg text-warning-fg border border-warning-border'
    when 'processing'
      'bg-info-bg text-info-fg border border-info-border'
    when 'completed'
      'bg-success-bg text-success-fg border border-success-border'
    when 'canceled', 'failed'
      'bg-error-bg text-error-fg border border-error-border'
    else
      'bg-smoke text-slate border border-muted'
    end
  end
end
