class ReturnAddressesController < ApplicationController
  before_action :set_return_address, only: [:show, :edit, :update, :destroy]

  def index
    @return_addresses = ReturnAddress.where(shared: true).or(ReturnAddress.where(user: current_user))
  end

  def show
  end

  def new
    @return_address = ReturnAddress.new
    @return_address.user = current_user if user_signed_in?
  end

  def edit
    authorize @return_address
  end

  def create
    @return_address = ReturnAddress.new(return_address_params)
    @return_address.user = current_user if user_signed_in?

    if @return_address.save
      # If this was created from the letter form, redirect back to the letter
      if params[:from_letter].present?
        redirect_to new_letter_path, notice: "Return address was successfully created. Please select it from the dropdown."
      else
        redirect_to @return_address, notice: "Return address was successfully created."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @return_address
    
    if @return_address.update(return_address_params)
      redirect_to @return_address, notice: "Return address was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @return_address
    
    @return_address.destroy
    redirect_to return_addresses_url, notice: "Return address was successfully destroyed."
  end

  private

  def set_return_address
    @return_address = ReturnAddress.find(params[:id])
  end

  def return_address_params
    params.require(:return_address).permit(:name, :line_1, :line_2, :city, :state, :postal_code, :country, :shared, :user_id)
  end
end 