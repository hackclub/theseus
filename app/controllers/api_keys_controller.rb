class APIKeysController < ApplicationController
  before_action :set_api_key, except: [:index, :new, :create]

  def index
    authorize APIKey
    @api_keys = policy_scope(APIKey)
    render Views::APIKeys::Index.new(api_keys: @api_keys)
  end

  def new
    authorize APIKey
    @api_key = APIKey.new(user: current_user)
    render Views::APIKeys::New.new(api_key: @api_key)
  end

  def create
    permitted_params = [:name, :pii, :qz_only]
    permitted_params << :may_impersonate if current_user.admin?

    @api_key = APIKey.new(params.require(:api_key).permit(*permitted_params).merge(user: current_user))

    authorize @api_key

    if @api_key.save
      redirect_to api_key_path(@api_key)
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
      redirect_to new_api_key_path(@api_key)
    end
  end

  def show
    authorize @api_key
    render Views::APIKeys::Show.new(api_key: @api_key)
  end

  def revoke_confirm
    authorize @api_key
    render Views::APIKeys::RevokeConfirm.new(api_key: @api_key)
  end

  def revoke
    authorize @api_key
    @api_key.revoke!
    flash[:success] = "terminated with extreme prejudice."
    redirect_to api_key_path(@api_key)
  end

  private

  def set_api_key
    @api_key = policy_scope(APIKey).find(params[:id])
  end
end
