require "set"

module Public
  class MapsController < ApplicationController
    include Frameable
    layout "public/frameable"

    def show
      @return_path = public_root_path
      @letters_data = Rails.cache.fetch("map_data", expires_in: 1.hour) do
        fetch_recent_letters_data
      end
    end

    private

    def fetch_recent_letters_data
      # Get mailed letters (any time) and letters received in the last 7 days
      recent_letters = Letter.joins(:address, :return_address)
        .where(
          "aasm_state = 'mailed' OR (aasm_state = 'received' AND received_at >= ?)",
          7.days.ago
        )
        .includes(:iv_mtr_events, :address, :return_address)

      letters_data = recent_letters.map do |letter|
        Rails.logger.info "Processing letter #{letter.public_id}"
        event_coords = build_letter_event_coordinates(letter)
        Rails.logger.info "Event coords for #{letter.public_id}: #{event_coords.inspect}"

        bubble_title = if letter.aasm_state == "received"
            "a letter was received here!"
          elsif letter.iv_mtr_events.blank?
            "a letter was mailed here!"
          else
            "a letter was last seen here!"
          end

        {
          coordinates: event_coords,
          current_location: event_coords.last,
          destination_coords: geocode_destination(letter.address),
          bubble_title: bubble_title,
        }
      end

      letters_data
    end

    def build_letter_event_coordinates(letter)
      coordinates = []
      Rails.logger.info "Building coordinates for letter #{letter.public_id}"

      # Mailed event coordinates
      if letter.mailed_at.present?
        Rails.logger.info "Adding mailed coordinates for #{letter.public_id}"
        coords = geocode_origin(letter.return_address)
        Rails.logger.info "Mailed coords: #{coords.inspect}"
        coordinates << coords
      end

      # USPS tracking event coordinates
      if letter.iv_mtr_events.present?
        Rails.logger.info "Processing #{letter.iv_mtr_events.count} USPS events for #{letter.public_id}"
        letter.iv_mtr_events.each do |event|
          if event[:locale_key]
            coords = geocode_usps_facility(event[:locale_key])
            Rails.logger.info "USPS facility coords for #{event[:locale_key]}: #{coords.inspect}"
            coordinates << coords if coords
          end
        end
      end

      # Received event coordinates
      if letter.received_at.present?
        Rails.logger.info "Adding received coordinates for #{letter.public_id}"
        coords = geocode_destination(letter.address)
        Rails.logger.info "Received coords: #{coords.inspect}"
        coordinates << coords
      end

      Rails.logger.info "Final coordinates for #{letter.public_id}: #{coordinates.inspect}"
      coordinates.compact
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
      {
        lat: result[:lat].to_f,
        lon: result[:lon].to_f,
      }
    end

    def geocode_destination(address)
      # Use non-exact geocoding (city only) to avoid doxing
      result = GeocodingService.geocode_address_model(address, exact: false)
      {
        lat: result[:lat].to_f,
        lon: result[:lon].to_f,
      }
    end

    def geocode_usps_facility(locale_key)
      result = GeocodingService::USPSFacilities.coords_for_locale_key(locale_key)
      return nil unless result

      {
        lat: result[:lat].to_f,
        lon: result[:lon].to_f,
      }
    end

    def format_location(address_or_return_address)
      if address_or_return_address.is_a?(Address)
        "#{address_or_return_address.city}, #{address_or_return_address.state}"
      else
        "#{address_or_return_address.city}, #{address_or_return_address.state}"
      end
    end
  end
end
