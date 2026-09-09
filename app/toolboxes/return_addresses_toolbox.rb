class ReturnAddressesToolbox < ApplicationToolbox
  default_param :return_address_id, :integer, "Return address ID", except: [ :list, :create ]

  tool "List sender return addresses visible to you (shared + your own). These are printed as the from-address on envelopes", access: :read do
    param :page, :integer, "Page number", optional: true
  end
  def list
    scope = ReturnAddress.where(shared: true).or(ReturnAddress.where(user: current_user))
    @return_addresses = paginate(scope.order(created_at: :desc))
  end

  tool "Show full detail for a sender return address", access: :read do; end
  def show
    @return_address = ReturnAddress.find(params[:return_address_id])
  end

  tool "Create a new sender return address for printing on letter envelopes", access: :write do
    param :name, :string, "Name / label (e.g. company or person)"
    param :line_1, :string, "Street address line 1"
    param :line_2, :string, "Street address line 2", optional: true
    param :city, :string, "City"
    param :state, :string, "State / province"
    param :postal_code, :string, "ZIP / postal code"
    param :country, :string, "Country code (e.g. US, CA)", optional: true
    param :shared, :boolean, "Visible to all users, not just the creator", optional: true
  end
  def create
    @return_address = ReturnAddress.new(
      params.permit(:name, :line_1, :line_2, :city, :state, :postal_code, :country, :shared)
    )
    @return_address.user = current_user
    @return_address.save!
    render :show
  end

  tool "Update a sender return address (owner or admin only)", access: :write do
    param :name, :string, "Name / label", optional: true
    param :line_1, :string, "Street address line 1", optional: true
    param :line_2, :string, "Street address line 2", optional: true
    param :city, :string, "City", optional: true
    param :state, :string, "State / province", optional: true
    param :postal_code, :string, "ZIP / postal code", optional: true
    param :country, :string, "Country code (e.g. US, CA)", optional: true
    param :shared, :boolean, "Visible to all users, not just the creator", optional: true
  end
  def update
    @return_address = ReturnAddress.find(params[:return_address_id])
    unless @return_address.user == current_user || admin?
      halt error: "Forbidden — you can only edit your own return addresses"
    end
    @return_address.update!(
      params.permit(:name, :line_1, :line_2, :city, :state, :postal_code, :country, :shared)
    )
    render :show
  end

  tool "Set a return address as your default for new letters", access: :write do; end
  def set_as_home
    @return_address = ReturnAddress.find(params[:return_address_id])
    unless @return_address.user == current_user || @return_address.shared? || admin?
      halt error: "You can only set your own or shared addresses as default"
    end
    current_user.update!(home_return_address: @return_address)
    render json: {
      message: "#{@return_address.display_name} is now your default return address",
      return_address_id: @return_address.id
    }
  end
end
