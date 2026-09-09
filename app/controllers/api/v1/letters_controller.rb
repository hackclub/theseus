module API
  module V1
    class LettersController < ApplicationController
      before_action :set_letter, only: [ :show, :mark_printed, :mark_mailed ]

      def show
        authorize @letter
      end

      def by_tag
        @letters = Letter.where("? = ANY(tags)", params[:tag])
        authorize @letters
        render :letters_collection
      end

      def mark_printed
        authorize @letter
        @letter.mark_printed!
        render json: { message: "Letter marked as printed" }
      end

      def mark_mailed
        authorize @letter
        @letter.mark_mailed!
        render json: { message: "Letter marked as mailed" }
      end

      private

      def set_letter
        if params[:id]&.start_with? "hackapost!"
          ind = USPS::Indicium.find_by_hashid!(params[:id][10...])
          @letter = ind.letter
          raise ActiveRecord::RecordNotFound if @letter.nil?
        else
          @letter = Letter.find_by_public_id!(params[:id])
        end
      end
    end
  end
end
