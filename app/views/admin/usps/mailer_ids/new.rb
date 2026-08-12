class Views::Admin::USPS::MailerIds::New < Views::Base
  def initialize(mailer_id:)
    @mailer_id = mailer_id
  end

  def view_template
    render Components::Shared::PageToolbar.new(title: "New Mailer ID")
    render Components::Admin::USPS::MailerIds::Form.new(mailer_id: @mailer_id)
  end
end
