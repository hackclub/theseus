class EasyPostService
  def self.client
    @client ||= EasyPost::Client.new(api_key: Rails.application.credentials.dig(:easypost, :api_key))
  end
end
