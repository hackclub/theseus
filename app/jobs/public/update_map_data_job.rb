class Public::UpdateMapDataJob < ApplicationJob
  queue_as :default

  good_job_control_concurrency_with(
    total_limit: 1,
    key: "update_map_data"
  )

  def perform
	return
    map_data = fetch_recent_letters_data
    Rails.cache.write("map_data", map_data, expires_in: 1.hour)
    map_data
  end

  private

  def fetch_recent_letters_data
    the_paranoid_few = Public::User.where(opted_out_of_map: true).pluck(:email)
    recent_letters = Letter.joins(:address, :return_address)
                           .where(
                             "aasm_state = 'mailed' OR (aasm_state = 'received' AND received_at >= ?)",
                             7.days.ago
                           )
                           .includes(:iv_mtr_events, :address, :return_address)
                           .where.not(recipient_email: the_paranoid_few)

    letters_data = recent_letters.map do |letter|
      event_coords = build_letter_event_coordinates(letter)

      bubble_title = if letter.aasm_state == "received"
          "a letter was received here!"
        elsif letter.iv_mtr_events.blank?
          "a letter was mailed here!"
        else
          "a letter was last seen here!"
        end

      # Find the last valid coordinate (in case the final event failed to geocode)
      current_location = event_coords.last

      {
        coordinates: event_coords,
        current_location: current_location,
        destination_coords: geocode_destination(letter.address),
        bubble_title: bubble_title,
        aasm_state: letter.aasm_state,
      }
    end.select { |letter_data| letter_data[:coordinates].present? }

    letters_data
  end

  def build_letter_event_coordinates(letter)
    coordinates = []

    # Mailed event coordinates
    if letter.mailed_at.present?
      coords = geocode_origin(letter.return_address)
      coordinates << coords
    end

    # USPS tracking event coordinates (ordered by scan datetime)
    if letter.iv_mtr_events.present?
      # Order events by scan datetime to get proper chronological order
      ordered_events = letter.iv_mtr_events.sort_by { |event| event.scan_datetime || event.happened_at }

      ordered_events.each do |event|
        begin
          hydrated = event.hydrated
          locale_key = hydrated.scan_locale_key
          if locale_key.present?
            coords = geocode_usps_facility(locale_key, event)
            coordinates << coords if coords
          end
        rescue => e
          Rails.logger.warn("Failed to process IV-MTR event #{event.id}: #{e.message}")
          # Continue processing other events
        end
      end
    end

    # Received event coordinates
    if letter.received_at.present?
      coords = geocode_destination(letter.address)
      coordinates << coords
    end

    coordinates.compact.reject { |coord| coord.nil? || coord[:lat].nil? || coord[:lon].nil? }
  end

  def geocode_origin(return_address)
    # Special case: anything in Shelburne goes to FIFTEEN_FALLS
    if return_address.city&.downcase&.include?("shelburne")
      return {
               lat: GeocodingService::FIFTEEN_FALLS[:lat].to_f,
               lon: GeocodingService::FIFTEEN_FALLS[:lon].to_f,
             }
    end

    # Use non-exact geocoding to avoid doxing
    result = GeocodingService.geocode_return_address(return_address, exact: false)
    if result && result[:lat] && result[:lon]
      {
        lat: result[:lat].to_f,
        lon: result[:lon].to_f,
      }
    else
      # Fallback to FIFTEEN_FALLS if geocoding fails
      {
        lat: GeocodingService::FIFTEEN_FALLS[:lat].to_f,
        lon: GeocodingService::FIFTEEN_FALLS[:lon].to_f,
      }
    end
  end

  def geocode_destination(address)
    # Use non-exact geocoding (city only) to avoid doxing
    result = GeocodingService.geocode_address_model(address, exact: false)
    return nil unless result && result[:lat] && result[:lon]

    {
      lat: result[:lat].to_f,
      lon: result[:lon].to_f,
    }
  end

  def geocode_usps_facility(locale_key, event)
    result = GeocodingService::USPSFacilities.coords_for_locale_key(locale_key, event)
    return nil unless result && result[:lat] && result[:lon]

    {
      lat: result[:lat].to_f,
      lon: result[:lon].to_f,
    }
  end
end
