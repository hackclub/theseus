module API
  module V1
    class LettersController < ApplicationController
      before_action :set_letter

      def show
        authorize @letter
      end

      private
      def set_letter
        @letter = Letter.find_by_public_id!(params[:id])
      end
    end
  end
end