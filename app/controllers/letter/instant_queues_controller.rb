class Letter::InstantQueuesController < Letter::QueuesController
  before_action :set_letter_queue, only: %i[ show edit update destroy ]

  def new
    @letter_queue = Letter::InstantQueue.new
  end

  def show
    @letters = @letter_queue.letters
  end

  private

  def set_letter_queue
    @letter_queue = Letter::InstantQueue.find_by!(slug: params[:id])
  end

  def letter_queue_params
    params.require(:letter_instant_queue).permit(
      :name,
      :type,
      :letter_height,
      :letter_width,
      :letter_weight,
      :letter_processing_category,
      :letter_mailer_id_id,
      :letter_return_address_id,
      :letter_return_address_name,
      :user_facing_title,
      :template,
      :postage_type,
      :usps_payment_account_id,
      :include_qr_code,
      :letter_mailing_date,
      tags: [],
    )
  end
end
