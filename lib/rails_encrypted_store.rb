require 'gibberish'

require "rails_encrypted_store/version"
require "rails_encrypted_store/railtie" if defined?(Rails::Railtie)

module RailsEncryptedStore
  extend ActiveSupport::Concern

  included do
    before_save :encrypt_store
  end

  module ClassMethods

    def encrypted_store(options={})
      attr_accessor :decrypted_data
      serialize :encrypted_data, Hash
      decrypted_data_accessor(options[:accessors]) if options.has_key? :accessors
    end

    def decrypted_data_accessor(*keys)
      Array(keys).flatten.each do |key|
        define_method("#{key}=") do |value|
          self.decrypted_data = {} unless decrypted_data.is_a?(Hash)
          decrypted_data[key] = value
          self.encrypted_data_will_change!
        end

        define_method(key) do
          self.decrypted_data = {} unless decrypted_data.is_a?(Hash)
          decrypted_data[key]
        end
      end
    end
  end

  def encrypt_store
    return unless decrypted_data
    self.encrypted_data = {} unless encrypted_data.is_a?(Hash)
    cipher = ::Gibberish::AES.new(self.aes_key)
    decrypted_data.try(:each) do |key, value|
      if value
        encrypted_data[key] = cipher.enc(value)
        send("encrypted_data_will_change!")
      else
        encrypted_data[key].delete
      end
    end
  end

  def decrypt_store(aes_key=nil)
    self.aes_key ||= aes_key
    self.decrypted_data = {} unless decrypted_data.is_a?(Hash)
    cipher = ::Gibberish::AES.new(self.aes_key)
    encrypted_data.each do |key, value|
      decrypted_data[key] = cipher.dec(encrypted_data[key]).force_encoding('UTF-8')
    end
  end

end