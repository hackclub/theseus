module Public
  class LSVController < ApplicationController
    include Frameable

    def show
      @lsv = LSV::SLUGS[params[:slug].to_sym]&.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @lsv && @lsv.email == current_public_user&.email
    rescue Norairrecord::RecordNotFoundError
      raise ActiveRecord::RecordNotFound
    end
  end
end
