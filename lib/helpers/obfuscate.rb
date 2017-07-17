require 'openssl'
require 'base64'

module Obfuscate
    def self.included(base)
        base.extend self
    end

    def cipher
        OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    end

    def cipher_key
        ENV['INTEGRATIONS_ID_CIPHER']
    end

    def decrypt(value)
        if value
            begin
                c = cipher.decrypt
                c.key = Digest::SHA256.digest(cipher_key)
                c.update(Base64.urlsafe_decode64(value.to_s)) + c.final
            rescue => e
                puts e
                return nil
            end
        end
    end

    def encrypt(value)
        if value
            c = cipher.encrypt
            c.key = Digest::SHA256.digest(cipher_key)
            Base64.urlsafe_encode64(c.update(value.to_s) + c.final)
        end
    end
end
