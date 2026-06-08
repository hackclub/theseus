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
    tag("row", "align-": "start between", "gap-": "2", style: "margin-bottom: 2lh;") do
      tag("column") do
        tag("row", "gap-": "1", "align-": "center") do
          h1(style: "margin: 0;") { @title }
          if @jumpcode
            render Components::Shared::Jumpcode.new(code: @jumpcode)
          elsif @jumpcode_path
            render Components::Shared::Jumpcode.new(path: @jumpcode_path)
          end
        end
        if @subtitle
          span(style: "color: var(--foreground2);") { @subtitle }
        end
      end
      if @actions_block
        tag("row", "gap-": "1", "align-": "center") do
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
