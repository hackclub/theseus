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
      path = path_for_record(result.record)
      return redirect_to path if path
      return redirect_back fallback_location: public_ids_path,
        alert: "#{result.type} #{params[:id]} exists, but there's no page for it."
    end

    # LSV fallback for tracking numbers (Airtable, not in PublicIdResolver)
    if params[:id].match?(/\A[A-Z0-9]{10,}\z/i)
      escaped_id = params[:id].gsub('\\') { '\\\\' }.gsub("'") { "\\'" }
      lsv = LSV::MarketingShipmentRequest.first_where("{Warehouse–Tracking Number} = '#{escaped_id}'")
      return redirect_to show_lsv_path(LSV.slug_for(lsv), lsv.id) if lsv
    end

    flash[:alert] = "nothing found at all."
    redirect_back fallback_location: public_ids_path
  rescue ActiveRecord::RecordNotFound => e
    flash[:alert] = "Record not found"
    redirect_back fallback_location: public_ids_path
  end

  private

  # url_for only works for records whose model name matches a route, which
  # leaves out users, billing profiles, batches and indicia. nil means "no
  # page for this one" and the caller sends the user back with an alert.
  def path_for_record(record)
    case record
    when Letter then letter_path(record)
    when Warehouse::Order then warehouse_order_path(record)
    when Warehouse::Template then warehouse_template_path(record)
    when Letter::Batch then letter_batch_path(record)
    when Warehouse::Batch then warehouse_batch_path(record)
    when USPS::Indicium
      if current_user.admin?
        inspect_indicium_path(record)
      elsif record.letter.present?
        public_letter_path(record.letter)
      end
    when User then (admin_user_path(record) if current_user.admin?)
    when BillingProfile then (hcb_payment_account_path(record) if record.user == current_user || current_user.admin?)
    end
  end
end
