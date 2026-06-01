class PublicIdsController < ApplicationController
  # GET /id/:public_id
  #
  skip_after_action :verify_authorized
  #
  def index
  end

  def lookup

    return redirect_back fallback_location: public_ids_path, alert: "well you gotta enter *something*..." unless params[:id].present?

    # The public_id contains the prefix that determines the model class
    prefix = params[:id].split("!").first&.downcase
    id_part = params[:id].split("!").last

    # Find the corresponding model based on the prefix
    case prefix
    when "mtr"
      @record = USPS::IVMTR::Event.find_by_public_id!(params[:id])
      @letter = @record.letter
      if current_user.admin?
        return redirect_to inspect_iv_mtr_event_path(@record)
      else
        if @letter.present?
          return redirect_to public_letter_path(@letter)
        else
          return redirect_back fallback_location: public_ids_path, alert: "MTR event found, but no associated letter...?"
        end
      end
    when "hackapost", "dev"
      @indicium = USPS::Indicium.find(id_part[1...])
      @letter = @indicium.letter
      if current_user.admin?
        return redirect_to inspect_indicium_path(@indicium)
      else
        if @letter.present?
          return redirect_to public_letter_path(@letter)
        else
          return redirect_back fallback_location: public_ids_path, alert: "indicium found, but no associated letter...?"
        end
      end
    else
      # bad hack:
      clazzes = ActiveRecord::Base.descendants.select { |c| c.included_modules.include?(PublicIdentifiable) }
      clazz = clazzes.find { |c| c.public_id_prefix == prefix }
      unless clazz.present?
        return search_by_tracking_number(params[:id])
      end
      @record = clazz.find_by_public_id(params[:id])
      unless @record.present?
        return redirect_back fallback_location: public_ids_path, alert: "no #{clazz.name} found with public id #{params[:id]}"
      end

      redirect_to url_for(@record)

    end
  rescue ActiveRecord::RecordNotFound => e
    flash[:alert] = "Record not found"
    redirect_back fallback_location: public_ids_path
  end

  private

  def search_by_tracking_number(tracking_number)
    return if tracking_number.blank?
    # Search for warehouse orders by tracking number
    warehouse_order = Warehouse::Order.find_by(tracking_number: tracking_number)
    if warehouse_order
      return redirect_to warehouse_order_path(warehouse_order)
    end

    lsv = LSV::MarketingShipmentRequest.first_where("{Warehouse–Tracking Number} = '#{tracking_number.gsub("'", "\\'")}'")

    if lsv
      return redirect_to show_lsv_path(LSV.slug_for(lsv), lsv.id)
    end

    # No package found with this tracking number
    flash[:alert] = "nothing found at all."
    redirect_back fallback_location: public_ids_path
  end
end
