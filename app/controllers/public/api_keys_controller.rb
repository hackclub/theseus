module Public
  class APIKeysController < ApplicationController
    before_action :set_api_key, except: [:index, :new, :create]
    before_action :authenticate_public_user!

    def index
      @api_keys = APIKey.where(public_user: current_public_user)
    end

    def new
      @api_key = APIKey.new(public_user: current_public_user)
    end

    def create
      @api_key = APIKey.new(params.require(:public_api_key).permit(:name).merge(public_user: current_public_user))

      if @api_key.save
        redirect_to public_api_key_path(@api_key)
      else
        flash[:error] = @api_key.errors.full_messages.to_sentence
        redirect_to new_public_api_key_path
      end
    end

    def show
    end

    def revoke_confirm
    end

    def revoke
      @api_key.revoke!
      flash[:success] = "terminated with extreme prejudice."
      redirect_to public_api_key_path(@api_key)
    end

    private

    def set_api_key
      @api_key = APIKey.where(public_user: current_public_user).find(params[:id])
    end
  end
end
