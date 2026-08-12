# frozen_string_literal: true

class Views::Admin::SourceTags::Edit < Views::Base
  def initialize(source_tag:)
    @source_tag = source_tag
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "Edit Source Tag")
    render Components::Admin::SourceTags::Form.new(source_tag: @source_tag)
  end
end
