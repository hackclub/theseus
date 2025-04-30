module Public
  class ImpersonationsController < ApplicationController
    def new
      authorize Impersonation
      @impersonation = Impersonation.new
    end

    def create
      @impersonation = Impersonation.new(impersonation_params.merge(user: current_user))

      authorize @impersonation

      if @impersonation.save
        public_user = Public::User.find_or_create_by!(email: impersonation_params[:target_email])
        session[:public_user_id] = public_user.id
        session[:public_impersonator_user_id] = current_user.id
        redirect_to public_root_path
      else
        render :new
      end
    end

    def stop_impersonating
      session[:public_user_id] = nil
      session[:public_impersonator_user_id] = nil
      redirect_to public_root_path
    end

    def impersonation_params
      params.require(:public_impersonation).permit(:target_email, :justification)
    end
  end
end