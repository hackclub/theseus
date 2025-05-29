require "set"

module Public
  class MapsController < ApplicationController
    include Frameable
    layout "public/frameable"

    def show
      @return_path = public_root_path
      @letters_data = fetch_recent_letters_data
    end

    private

    def fetch_recent_letters_data
      # Get letters mailed in the last 7 days
      recent_letters = Letter.joins(:address, :return_address)
        .where("mailed_at >= ?", 7.days.ago)
        .includes(:iv_mtr_events, :address, :return_address)

      # Get all unique locations for batch geocoding
      all_locations = Set.new

      letters_data = recent_letters.map do |letter|
        events = letter.events
        origin_location = format_location(letter.return_address)
        destination_location = format_location(letter.address)

        all_locations.add(origin_location)
        all_locations.add(destination_location)
        events.each { |event| all_locations.add(event[:location]) if event[:location] }

        {
          id: letter.public_id,
          title: letter.display_name,
          status: letter.aasm_state,
          origin: origin_location,
          destination: destination_location,
          events: events,
          last_location: events.last&.dig(:location) || origin_location,
        }
      end

      # Batch geocode all locations
      geocoded_locations = GeocodingService.batch_geocode(all_locations.to_a)

      # Add coordinates to letter data
      letters_data.each do |letter_data|
        letter_data[:origin_coords] = geocoded_locations[letter_data[:origin]]
        letter_data[:destination_coords] = geocoded_locations[letter_data[:destination]]
        letter_data[:last_location_coords] = geocoded_locations[letter_data[:last_location]]

        letter_data[:events].each do |event|
          event[:coordinates] = geocoded_locations[event[:location]]
        end
      end

      letters_data
    end

    def format_location(address_or_return_address)
      if address_or_return_address.is_a?(Address)
        "#{address_or_return_address.city}, #{address_or_return_address.state}"
      else
        "#{address_or_return_address.city}, #{address_or_return_address.state}"
      end
    end

    def format_event(event)
      {
        happened_at: event[:happened_at],
        location: event[:location],
        description: event[:description],
        source: event[:source],
      }
    end
  end
end
