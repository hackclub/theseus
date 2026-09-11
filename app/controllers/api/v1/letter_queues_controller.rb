module API
  module V1
    class LetterQueuesController < ApplicationController
      include AddressParameterParsing

      before_action :set_letter_queue, only: [ :show, :create_letter ]
      before_action :set_instant_letter_queue, only: [ :create_instant_letter, :queued ]

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "Queue not found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: {
          error: "Validation failed",
          details: e.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def show
        authorize @letter_queue
      end

      # this should REALLY be websockets or some shit
      # but it's not, so we're just going to poll
      # i'm not braining well enough to do it right anytime soon
      def queued
        raise Pundit::NotAuthorizedError unless current_token&.pii?

        @expand = [ :label ]

        @letters = @letter_queue.letters.pending
      end

      def create_letter
        authorize @letter_queue

        addy = parse_address_from_params(letter_params[:address])
        return unless addy

        @letter = @letter_queue.create_letter!(
          addy,
          letter_params.except(:address).merge(user: current_user),
        )
        render :create_letter, status: :created

      end

      def create_instant_letter
        authorize @letter_queue, policy_class: Letter::QueuePolicy

        addy = parse_address_from_params(letter_params[:address])
        return unless addy

        @letter = @letter_queue.process_letter_instantly!(
          addy,
          letter_params.except(:address).merge(user: current_user),
        )
        @expand << :label
        render :create_letter, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Queue not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      rescue Letter::InstantQueue::PurchaseUncertain => e
        # 409, not 500: the request is finished, but whether postage was bought
        # is unknown. Name the letter so a human can go and look.
        render json: {
          error: "postage_unresolved",
          letter_id: e.letter.public_id,
          message: e.message
        }, status: :conflict
      rescue USPS::IndiciumPurchase::PurchaseFailed => e
        render json: {
          error: "postage_purchase_failed",
          refunded: e.refunded?,
          message: e.message
        }, status: :bad_gateway
      rescue Billing::Rejected, Billing::InFlight => e
        render json: { error: "payment_failed", message: e.message }, status: :payment_required
      end

      private

      # Batch queues are owner-or-admin: Letter::QueuePolicy#create_letter? only
      # asks for a logged-in user, so the scoping is what keeps someone else's
      # queue from taking your letters. (Instant queues are open on purpose and
      # go through set_instant_letter_queue instead.)
      def set_letter_queue
        @letter_queue = policy_scope(Letter::Queue).find_by!(slug: params[:id])
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
            :country
          ],
        )
      end
    end
  end
end
