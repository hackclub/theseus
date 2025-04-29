module ButtonHelper
  def primary_button_to(name, url, options = {})
    options[:class] ||= ""
    options[:class] += " btn btn-md btn-primary"

    button_to(name, url, options)
  end

  def primary_link_to(name, url, options = {}, &block)
    options[:class] ||= ""
    options[:class] += " btn btn-md btn-primary"

    if block_given?
      link_to(url, options, &block)
    else
      link_to(name, url, options)
    end
  end

  def primary_outline_link_to(name, url, options = {}, &block)
    options[:class] ||= ""
    options[:class] += " btn btn-small outlined"

    if block_given?
      link_to(url, options, &block)
    else
      link_to(name, url, options)
    end
  end

  def secondary_link_to(name, url, options = {}, &block)
    options[:class] ||= ""
    options[:class] += " btn btn-sm btn-secondary"

    if block_given?
      link_to(url, options, &block)
    else
      link_to(name, url, options)
    end
  end

  def danger_button_to(name, url, options = {})
    options[:class] ||= ""
    options[:class] += " btn btn-md btn-danger"

    # Add confirmation by default for dangerous actions
    options[:data] ||= {}
    options[:data][:confirm] ||= "Are you sure? This action cannot be undone."

    button_to(name, url, options)
  end

  def warning_link_to(name, url, options = {}, &block)
    options[:class] ||= ""
    options[:class] += " btn btn-md btn-warning"

    if block_given?
      link_to(url, options, &block)
    else
      link_to(name, url, options)
    end
  end

  def success_link_to(name, url, options = {}, &block)
    options[:class] ||= ""
    options[:class] += " btn btn-md btn-success"

    if block_given?
      link_to(url, options, &block)
    else
      link_to(name, url, options)
    end
  end

  # Common icons you can use with buttons
  def back_icon
    '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 17l-5-5m0 0l5-5m-5 5h12" />
    </svg>'.html_safe
  end

  def edit_icon
    '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
    </svg>'.html_safe
  end

  def document_icon
    '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
    </svg>'.html_safe
  end

  def check_icon
    '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
    </svg>'.html_safe
  end

  def download_icon
    '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
    </svg>'.html_safe
  end

  def eye_icon
    '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
      <circle cx="12" cy="12" r="3"></circle>
    </svg>'.html_safe
  end

  def plus_icon
    '<svg xmlns="http://www.w3.org/2000/svg" class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
    </svg>'.html_safe
  end

  def create_button(url, text = "Create", options = {}, &block)
    options[:class] ||= ""
    options[:class] += " btn success"

    if block_given?
      success_link_to(url, options) do
        plus_icon + " #{text}"
      end
    else
      success_link_to(plus_icon + " #{text}", url, options)
    end
  end
end
