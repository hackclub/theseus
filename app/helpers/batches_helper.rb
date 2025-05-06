module BatchesHelper
  def batch_status_badge(status, addtl_class='')
    clazz, text = case status.to_s
                  when 'awaiting_field_mapping'
                    ['warning', 'awaiting field mapping']
                  when 'fields_mapped'
                    ['info', 'ready to process']
                  when 'processed'
                    ['success', 'processed']
                  else
                    ['muted', status.to_s.humanize(capitalize: false)]
                  end
    content_tag('span', text, class: "badge #{clazz} #{addtl_class}".strip)
  end
end
