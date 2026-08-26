module AddressParameterParsing
  extend ActiveSupport::Concern

  private

  def parse_address_from_params(address_params)
    if address_params.blank?
      render json: { error: "address is required" }, status: :unprocessable_entity
      return nil
    end

    # Normalize country name using FrickinCountryNames
    country = FrickinCountryNames.find_country(address_params[:country])
    if country.nil?
      render json: { error: "couldn't figure out country name #{address_params[:country]}" }, status: :unprocessable_entity
      return nil
    end

    # Create address with normalized country
    normalized_address_params = address_params.merge(country: country.alpha2)
    # Normalize state name to abbreviation
    normalized_address_params[:state] = FrickinCountryNames.normalize_state(country, normalized_address_params[:state])

    addy = Address.new(normalized_address_params)
    addy.validate!
    addy
  end

  def permit_address_params
    params.require(:address).permit(
      :first_name,
      :last_name,
      :line_1,
      :line_2,
      :city,
      :state,
      :postal_code,
      :country,
      :phone_number
    )
  end
end
