# frozen_string_literal: true

class Views::Admin::CommonTags::New < Views::Base
  def initialize(common_tag:)
    @common_tag = common_tag
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "New Tag")
    render Components::Admin::CommonTags::Form.new(common_tag: @common_tag)
  end
end
