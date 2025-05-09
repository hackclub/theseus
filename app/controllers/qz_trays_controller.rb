class QZTraysController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token, only: [:sign]
  skip_before_action :authenticate_user!, only: [:test_print]
  def cert
    send_data QZTrayService.certificate
  end

  def settings
  end

  def sign
    send_data QZTrayService.sign(params.require(:request))
  end

  def test_print
    send_file(Rails.root.join('app', 'lib', 'test_print.pdf'), type: 'application/pdf', disposition: 'inline')
  end
end