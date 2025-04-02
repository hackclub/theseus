class PublicIdentifiableController < ApplicationController
  # GET /id/:public_id
  def show
    # The public_id contains the prefix that determines the model class
    prefix = params[:public_id].split('!').first&.downcase
    
    # Find the corresponding model based on the prefix
    case prefix
    when 'ltr'
      @record = Letter.find_by_public_id!(params[:public_id])
      redirect_to letter_path(@record)
    when 'pkg'
      @record = Warehouse::Order.find_by_public_id!(params[:public_id])
      redirect_to warehouse_order_path(@record)
    else
      # If no matching prefix is found, return 404
      raise ActiveRecord::RecordNotFound, "No record found with public_id: #{params[:public_id]}"
    end
  rescue ActiveRecord::RecordNotFound => e
    flash[:alert] = "Record not found"
    redirect_to root_path
  end
end 