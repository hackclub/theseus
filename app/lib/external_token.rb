class ExternalToken < SimpleStructuredSecrets
  def initialize(type)
    @org = "th"
    @type = type
  end

  def generate
    random = base62_encode(SecureRandom.rand(10 ** 60)).to_s[0...30]
    "#{@org}_#{@type}_#{Rails.env.production? ? "live" : "dev"}_#{random}#{calc_checksum(random)}"
  end
end