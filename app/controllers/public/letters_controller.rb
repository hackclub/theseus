module Public
  class LettersController < ApplicationController
    before_action :set_letter

    def show
      render "public/letters/show"
    end

    def mark_received
      if @letter.may_mark_received?
        @letter.mark_received!
        @received = true
        return render :show
      else
        flash[:alert] = "huh?"
        return render :show
      end
    end

    private
    def set_letter
      @letter = Letter.find_by_public_id!(params[:id])
      @events = @letter.events
    end
  end
end