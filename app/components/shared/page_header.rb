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
    div(class: "page-header") do
      div do
        div(class: "page-title-group") do
          h1(class: "page-title") { @title }
          if @jumpcode
            render Components::Shared::Jumpcode.new(code: @jumpcode)
          elsif @jumpcode_path
            render Components::Shared::Jumpcode.new(path: @jumpcode_path)
          end
        end
        if @subtitle
          p(class: "page-subtitle mt-1") { @subtitle }
        end
      end
      if @actions_block
        div(class: "page-actions") do
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
