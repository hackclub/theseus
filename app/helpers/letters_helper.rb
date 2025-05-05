module LettersHelper
  def letter_status_badge(status, addtl_class='nil')

    clazz, text = case status.to_s
                  when 'queued'
                    ['bg-muted', 'queued']
                  when 'pending'
                    ['pending', 'ready to print']
                  when "printed"
                    ["info", "printed"]
                  when "mailed"
                    ["success", "mailed"]
                  when "canceled", "failed"
                    "bg-error-bg text-error-fg border border-error-border"
                  else
                    "bg-smoke text-slate border border-muted"
                  end
    content_tag('span', text, :class => "badge #{clazz} #{addtl_class}".strip)
  end
end
