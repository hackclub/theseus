module API
  module V1
    class LetterQueuesController < ApplicationController
      before_action :set_letter_queue

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "Queue not found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: {
          error: "Validation failed",
          details: e.record.errors.full_messages,
        }, status: :unprocessable_entity
      end

      rescue_from USPS::Indicium::Error do |e|
        render json: {
          error: "Failed to purchase indicia",
          details: e.message,
        }, status: :unprocessable_entity
      end

      def show
        authorize @letter_queue
      end

      def create_letter
        authorize @letter_queue

        # Normalize country name using FrickinCountryNames
        country = FrickinCountryNames.find_country(letter_params[:address][:country])
        if country.nil?
          render json: { error: "couldn't figure out country name #{letter_params[:address][:country]}" }, status: :unprocessable_entity
          return
        end

        # Create address with normalized country
        address_params = letter_params[:address].merge(country: country.alpha2)
        addy = Address.new(address_params)

        @letter = @letter_queue.create_letter!(
          addy,
          letter_params.except(:address).merge(user: current_user),
        )

        render @letter, status: :created
        #   rescue ActiveRecord::RecordInvalid => e
        # render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def create_instant_letter
        queue = Letter::InstantQueue.find_by!(slug: params[:id])

        address = Address.create!(
          name: params[:address][:name],
          street1: params[:address][:street1],
          street2: params[:address][:street2],
          city: params[:address][:city],
          state: params[:address][:state],
          zip: params[:address][:zip],
          country: params[:address][:country],
        )

        letter = queue.process_letter_instantly!(address)

        render json: {
          letter: {
            id: letter.public_id,
            status: letter.aasm_state,
            label_url: letter.label.attached? ? rails_blob_url(letter.label) : nil,
            created_at: letter.created_at,
          },
        }, status: :created
      end

      private

      def set_letter_queue
        @letter_queue = Letter::Queue.find_by!(slug: params[:id])
      end

      def letter_params
        params.permit(
          :rubber_stamps,
          :recipient_email,
          :idempotency_key,
          metadata: {},
          address: [
            :first_name,
            :last_name,
            :line_1,
            :line_2,
            :city,
            :state,
            :postal_code,
            :country,
          ],
        )
      end
    end
  end
end
