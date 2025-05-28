module API
  module V1
    class LettersController < ApplicationController
      before_action :set_letter, only: [:show, :mark_printed]

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

      private

      def set_letter
        @letter = Letter.find_by_public_id!(params[:id])
      end
    end
  end
end
