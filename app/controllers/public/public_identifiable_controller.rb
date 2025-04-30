module Public
  class PublicIdentifiableController < ApplicationController
    def show
      prefix = params[:public_id].split("!").first&.downcase

      case prefix
      when "ltr"
        @record = Letter.find_by_public_id!(params[:public_id])
        redirect_to public_letter_path(@record)
      when "pkg"
        @record = Warehouse::Order.find_by_public_id!(params[:public_id])
        redirect_to public_package_path(@record)
      else
        raise ActiveRecord::RecordNotFound, "no record found with public_id: #{params[:public_id]}"
      end
    rescue ActiveRecord::RecordNotFound => e
      flash[:alert] = "what are you even looking for..?"
      redirect_to public_root_path
    end
  end
end