# frozen_string_literal: true

class Components::Shared::PageHeader < Components::Base
  def initialize(title:, subtitle: nil, jumpcode: nil, jumpcode_path: nil)
    @title = title
    @subtitle = subtitle
    @jumpcode = jumpcode
    @jumpcode_path = jumpcode_path
    @actions_block = nil
  end

  def view_template
    div(style: "display:flex;align-items:start;justify-content:space-between;gap:1rem;margin-bottom:2rem") do
      div(style: "display:flex;flex-direction:column") do
        div(style: "display:flex;gap:0.5rem;align-items:center") do
          h1(style: "margin: 0;") { @title }
          if @jumpcode
            render Components::Shared::Jumpcode.new(code: @jumpcode)
          elsif @jumpcode_path
            render Components::Shared::Jumpcode.new(path: @jumpcode_path)
          end
        end
        if @subtitle
          span(style: "color:GrayText") { @subtitle }
        end
      end
      if @actions_block
        div(style: "display:flex;gap:0.5rem;align-items:center") do
          @actions_block.call
        end
      end
    end
  end

  def with_actions(&block)
    @actions_block = block
    self
  end
end
