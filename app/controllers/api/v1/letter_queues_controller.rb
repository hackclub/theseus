module API
  module V1
    class LetterQueuesController < ApplicationController
      before_action :set_letter_queue, only: [:show, :create_letter]
      before_action :set_instant_letter_queue, only: [:create_instant_letter, :queued]

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "Queue not found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        Honeybadger.notify(e)
        render json: {
          error: "Validation failed",
          details: e.record.errors.full_messages,
        }, status: :unprocessable_entity
      end

      def show
        authorize @letter_queue
      end

      # this should REALLY be websockets or some shit
      # but it's not, so we're just going to poll
      # i'm not braining well enough to do it right anytime soon
      def queued
        # authorize @letter_queue, policy_class: Letter::QueuePolicy
        raise Pundit::NotAuthorizedError unless current_token&.pii?

        return render json: { error: "no" } unless @letter_queue.is_a?(Letter::InstantQueue)
        @expand = [:label]

        @letters = @letter_queue.letters.pending
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
        # Normalize state name to abbreviation
        address_params[:state] = FrickinCountryNames.normalize_state(country, address_params[:state])
        addy = Address.new(address_params)

        @letter = @letter_queue.create_letter!(
          addy,
          letter_params.except(:address).merge(user: current_user),
        )
        render :create_letter, status: :created

        #   rescue ActiveRecord::RecordInvalid => e
        # render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def create_instant_letter
        authorize @letter_queue, policy_class: Letter::QueuePolicy

        # Normalize country name using FrickinCountryNames
        country = FrickinCountryNames.find_country(letter_params[:address][:country])
        if country.nil?
          render json: { error: "couldn't figure out country name #{letter_params[:address][:country]}" }, status: :unprocessable_entity
          return
        end

        # Create address with normalized country
        address_params = letter_params[:address].merge(country: country.alpha2)
        # Normalize state name to abbreviation
        address_params[:state] = FrickinCountryNames.normalize_state(country, address_params[:state])
        addy = Address.new(address_params)

        @letter = @letter_queue.process_letter_instantly!(
          addy,
          letter_params.except(:address).merge(user: current_user),
        )
        @expand << :label
        render :create_letter, status: :created
      rescue ActiveRecord::RecordNotFound
        return render json: { error: "Queue not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        return render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end

      private

      def set_letter_queue
        @letter_queue = Letter::Queue.find_by!(slug: params[:id])
        # grossest hack on the planet, nora why are you like this
        raise ActiveRecord::RecordNotFound if @letter_queue.is_a?(Letter::InstantQueue)
      end

      def set_instant_letter_queue
        @letter_queue = Letter::InstantQueue.find_by!(slug: params[:id])
      end

      def letter_params
        params.permit(
          :rubber_stamps,
          :recipient_email,
          :idempotency_key,
          :return_address_name,
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

      def normalize_country(country)
        return "US" if country.blank? || country.downcase == "usa" || country.downcase == "united states"
        country
      end
    end
  end
end
