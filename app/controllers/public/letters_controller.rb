module Public
  class LettersController < ApplicationController
    include Frameable

    before_action :set_letter

    def show
      @framed = params[:framed].present? ? params[:framed] == 'true' : request.headers["Sec-Fetch-Dest"] == "iframe"
      render "public/letters/show"
    end

    def mark_received
      @framed = params[:framed]

      if @letter.may_mark_received?
        @letter.mark_received!
        @received = true
        frame_aware_redirect_to public_letter_path(@letter)
      else
        flash[:alert] = "huh?"
        return frame_aware_redirect_to public_letter_path(@letter)
      end
    end

    def mark_mailed
      if @letter.may_mark_mailed?
        @letter.mark_mailed!
        frame_aware_redirect_to public_letter_path(@letter)
      else
        flash[:alert] = "huh?"
        return frame_aware_redirect_to public_letter_path(@letter)
      end
    end

    private
    def set_letter
      @letter = Letter.find_by_public_id!(params[:id])
      @events = @letter.events
    end
  end
end