class PublicIdsController < ApplicationController
  # GET /id/:public_id
  #
  skip_after_action :verify_authorized
  #
  def index
  end

  def lookup
    # The public_id contains the prefix that determines the model class
    prefix = params[:id].split("!").first&.downcase
    id_part = params[:id].split("!").last

    # Find the corresponding model based on the prefix
    case prefix
    when "mtr"
      @record = USPS::IVMTR::Event.find_by_public_id!(params[:id])
      @letter = @record.letter
      if current_user.admin?
        redirect_to inspect_iv_mtr_event_path(@record)
      else
        if @letter.present?
          redirect_to public_letter_path(@letter)
        else
          redirect_to public_ids_path, alert: "MTR event found, but no associated letter...?"
        end
      end
    when "hackapost", "dev"
      @indicium = USPS::Indicium.find(id_part[1...])
      @letter = @indicium.letter
      if current_user.admin?
        redirect_to inspect_indicium_path(@indicium)
      else
        if @letter.present?
          redirect_to public_letter_path(@letter)
        else
          redirect_to public_ids_path, alert: "indicium found, but no associated letter...?"
        end
      end
    else
      # bad hack:
      clazzes = ActiveRecord::Base.descendants.select { |c| c.included_modules.include?(PublicIdentifiable) }
      clazz = clazzes.find { |c| c.public_id_prefix == prefix }
      unless clazz.present?
        return redirect_to public_ids_path, alert: "don't think we have that prefix: #{prefix}"
      end
      @record = clazz.find_by_public_id(params[:id])
      unless @record.present?
        return redirect_to public_ids_path, alert: "no #{clazz.name} found with public id #{params[:id]}"
      end

      redirect_to url_for(@record)

      # If no matching prefix is found, return 404
      # raise ActiveRecord::RecordNotFound, "No record found with public_id: #{params[:id]}"
    end
  rescue ActiveRecord::RecordNotFound => e
    flash[:alert] = "Record not found"
    redirect_to public_ids_path
  end
end
