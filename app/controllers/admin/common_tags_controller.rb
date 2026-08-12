# frozen_string_literal: true

module Admin
  class CommonTagsController < Admin::ApplicationController
    skip_after_action :verify_authorized

    def index
      @common_tags = CommonTag.all.order(:tag)
      render Views::Admin::CommonTags::Index.new(common_tags: @common_tags)
    end

    def new
      render Views::Admin::CommonTags::New.new(common_tag: CommonTag.new)
    end

    def create
      @common_tag = CommonTag.new(common_tag_params)
      if @common_tag.save
        redirect_to admin_common_tags_path, notice: "Tag created."
      else
        render Views::Admin::CommonTags::New.new(common_tag: @common_tag), status: :unprocessable_entity
      end
    end

    def edit
      render Views::Admin::CommonTags::Edit.new(common_tag: resource)
    end

    def update
      if resource.update(common_tag_params)
        redirect_to admin_common_tags_path, notice: "Tag updated."
      else
        render Views::Admin::CommonTags::Edit.new(common_tag: resource), status: :unprocessable_entity
      end
    end

    def destroy
      resource.destroy
      redirect_to admin_common_tags_path, notice: "Tag deleted."
    end

    private

    def resource = @resource ||= CommonTag.find(params[:id])
    def common_tag_params = params.require(:common_tag).permit(:tag, :implies_ysws)
  end
end
