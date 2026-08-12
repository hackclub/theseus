# frozen_string_literal: true

module Admin
  class SourceTagsController < Admin::ApplicationController
    skip_after_action :verify_authorized

    def index
      @source_tags = SourceTag.all.order(:name)
      render Views::Admin::SourceTags::Index.new(source_tags: @source_tags)
    end

    def show
      render Views::Admin::SourceTags::Show.new(source_tag: resource)
    end

    def new
      render Views::Admin::SourceTags::New.new(source_tag: SourceTag.new)
    end

    def create
      @source_tag = SourceTag.new(source_tag_params)
      if @source_tag.save
        redirect_to admin_source_tags_path, notice: "Created."
      else
        render Views::Admin::SourceTags::New.new(source_tag: @source_tag), status: :unprocessable_entity
      end
    end

    def edit
      render Views::Admin::SourceTags::Edit.new(source_tag: resource)
    end

    def update
      if resource.update(source_tag_params)
        redirect_to admin_source_tag_path(resource), notice: "Updated."
      else
        render Views::Admin::SourceTags::Edit.new(source_tag: resource), status: :unprocessable_entity
      end
    end

    def destroy
      resource.destroy
      redirect_to admin_source_tags_path, notice: "Deleted."
    end

    private

    def resource = @resource ||= SourceTag.find(params[:id])
    def source_tag_params = params.require(:source_tag).permit(:name, :owner, :slug)
  end
end
