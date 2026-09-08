class PublicIdsController < ApplicationController
  # GET /id/:public_id
  #
  skip_after_action :verify_authorized
  #
  def index
  end

  def lookup
    return redirect_back fallback_location: public_ids_path, alert: "well you gotta enter *something*..." unless params[:id].present?

    prefix = params[:id].split("!").first&.downcase

    # Special cases with admin-specific routing
    case prefix
    when "mtr"
      @record = USPS::IVMTR::Event.find_by_public_id!(params[:id])
      @letter = @record.letter
      if current_user.admin?
        return redirect_to inspect_iv_mtr_event_path(@record)
      elsif @letter.present?
        return redirect_to public_letter_path(@letter)
      else
        return redirect_back fallback_location: public_ids_path, alert: "MTR event found, but no associated letter...?"
      end
    when "hackapost", "dev"
      result = PublicIdResolver.resolve(params[:id])
      if result&.record.is_a?(USPS::Indicium)
        @indicium = result.record
        @letter = @indicium.letter
        if current_user.admin?
          return redirect_to inspect_indicium_path(@indicium)
        elsif @letter.present?
          return redirect_to public_letter_path(@letter)
        else
          return redirect_back fallback_location: public_ids_path, alert: "indicium found, but no associated letter...?"
        end
      end
      return redirect_back fallback_location: public_ids_path, alert: "nothing found for that hackapost ID"
    end

    # Generic resolution via PublicIdResolver
    result = PublicIdResolver.resolve(params[:id])
    if result
      return redirect_to url_for(result.record)
    end

    # LSV fallback for tracking numbers (Airtable, not in PublicIdResolver)
    if params[:id].match?(/\A[A-Z0-9]{10,}\z/i)
      lsv = LSV::MarketingShipmentRequest.first_where("{Warehouse–Tracking Number} = '#{params[:id].gsub("'", "\\'")}'")
      return redirect_to show_lsv_path(LSV.slug_for(lsv), lsv.id) if lsv
    end

    flash[:alert] = "nothing found at all."
    redirect_back fallback_location: public_ids_path
  rescue ActiveRecord::RecordNotFound => e
    flash[:alert] = "Record not found"
    redirect_back fallback_location: public_ids_path
  end
end
