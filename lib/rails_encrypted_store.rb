require 'gibberish'
require "rails_encrypted_store/version"
require "rails_encrypted_store/railtie" if defined?(Rails::Railtie)

module RailsEncryptedStore
  extend ActiveSupport::Concern
  extend ActiveRecord::Store

  module ClassMethods
    def encrypted_store(store_attribute, options = {})
      attr_accessor "plain_#{store_attribute}"
      store(store_attribute, options)
    end
  end

  def encrypt_attribute(store_attribute, key, value)
    self.send(store_attribute)[key] = cipher(store_attribute).enc(value)
  end

  def decrypt_store(store_attribute)
    self.send("#{store_attribute}_key") || self.send("#{store_attribute}_key=", store_attribute_key)
    attribute = initialize_store_attribute("plain_#{store_attribute}")
    send(store_attribute).each do |key, value|
      attribute[key] = cipher(store_attribute).dec(send(store_attribute)[key]).force_encoding('UTF-8')
    end
  end

  def cipher(store_attribute)
    return @cipher if @cipher
    @cipher = Gibberish::AES.new(send("#{store_attribute}_key"))
  end

  private

    def read_store_attribute(store_attribute, key)
      attribute = initialize_store_attribute("plain_#{store_attribute}")
      attribute[key]
    end

    def write_store_attribute(store_attribute, key, value)
      attribute = initialize_store_attribute("plain_#{store_attribute}")
      if !value
        attribute[key].delete
        self.send(store_attribute)[key].delete
      end
      if value != attribute[key]
        send :"#{store_attribute}_will_change!"
        attribute[key] = value
        encrypt_attribute(store_attribute, key, value)
      end
    end

end