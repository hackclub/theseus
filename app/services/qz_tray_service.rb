class QZTrayService
  class << self
    def private_key
      @private_key ||= OpenSSL::PKey.read(File.read(File.join(ENV["QZ_CERTS_PATH"], "private-key.pem")), ENV["QZ_PK_PASSWORD"])
    end

    def certificate
      @cert ||= File.read(File.join(ENV["QZ_CERTS_PATH"], "digital-certificate.txt"))
    end

    def sign(message)
      digest = OpenSSL::Digest::SHA512.new
      sig = private_key.sign(digest, message)
      Base64.encode64(sig)
    end
  end
end
