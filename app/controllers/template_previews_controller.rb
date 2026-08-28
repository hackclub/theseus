class TemplatePreviewsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def index
    @templates = SnailMail::Components::Registry.available_templates
  end

  def show
    template = params[:id]
    include_qr_code = params[:qr].present?

    mock_letter = create_mock_letter

    pdf = SnailMail::PhlexService.generate_label(mock_letter, { template:, include_qr_code: })
    send_data pdf.render, type: "application/pdf", disposition: "inline"
  end

  private

  def create_mock_letter
    return_address = OpenStruct.new(
      name: "Hack Club",
      line_1: "212 Battery St",
      line_2: "Suite 3",
      city: "Burlington",
      state: "VT",
      postal_code: "05401",
      country: "US",
    )

    names = [
      "Orpheus",
      "Heidi Hakkuun", 
      "Dinobox",
      "Arcadius",
      "Cap'n Trashbeard",
    ]

    usps_mailer_id = OpenStruct.new(mid: "111111")
    sender, recipient = names.sample(2)

    OpenStruct.new(
      address: SnailMail::Preview::FakeAddress.new(
        line_1: "8605 Santa Monica Blvd",
        line_2: "Apt. 86294", 
        city: "West Hollywood",
        state: "CA",
        postal_code: "90069",
        country: "US",
        name_line: sender,
      ),
      return_address:,
      return_address_name_line: recipient,
      postage_type: "stamps",
      postage: 0.73,
      usps_mailer_id:,
      imb_serial_number: "1337",
      metadata: {},
      rubber_stamps: "here's\n where\n rubber stamps go!",
      public_id: "ltr!PR3V13W",
    )
  end
end
