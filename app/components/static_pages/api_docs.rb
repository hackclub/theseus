# frozen_string_literal: true

class Components::StaticPages::APIDocs < Components::Base
  def initialize(markdown:)
    @markdown = markdown
  end

  def view_template
    div(class: "api-docs-container") do
      div(class: "markdown-body") do
        raw safe rendered_html
      end
    end
  end

  private

  def rendered_html
    renderer = Redcarpet::Render::HTML.new(with_toc_data: true)
    md = Redcarpet::Markdown.new(renderer, fenced_code_blocks: true, tables: true, autolink: true)
                       .render(@markdown)
    md
      .gsub("%AI-COPY-BUTTON%", capture { ai_copy_button })
      .gsub("%API-KEY-BUTTON%", capture { api_key_button })
  end

  def api_key_button
    render(Primer::Beta::Button.new(
      size: :small,
      href: new_api_key_path,
      target: "_blank",
      tag: :a,
    )) do |c|
      c.with_leading_visual_icon(icon: :key)
      "make one right now!"
    end
  end

  def ai_copy_button
    button(
      class: "api-docs-copy-btn",
      onclick: safe("let b=this;fetch('#{api_docs_path(format: :md)}').then(r=>r.text()).then(t=>navigator.clipboard.writeText(t)).then(()=>{b.querySelector('span').textContent='Copied!';setTimeout(()=>b.querySelector('span').textContent='Copy LLM-friendly version as Markdown',2000)})")
    ) do
      render Primer::Beta::Octicon.new(icon: :copy, size: :small)
      span { "Copy LLM-friendly version as Markdown" }
    end
  end
end
