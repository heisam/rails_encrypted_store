require 'gibberish'
require 'active_support/core_ext/hash/indifferent_access'
require "rails_encrypted_store/version"
require "rails_encrypted_store/railtie" if defined?(Rails::Railtie)

module RailsEncryptedStore
  extend ActiveSupport::Concern

  included do
    class_attribute :encrypted_attributes, instance_accessor: false
    self.encrypted_attributes = {}
  end

  module ClassMethods

    def encrypted_store(store_attribute, options = {})
      attr_accessor "plain_#{store_attribute}"
      serialize store_attribute, IndifferentCoder.new(options[:coder])
      store_accessor(store_attribute, options[:accessors]) if options.has_key? :accessors
    end

    def store_accessor(store_attribute, *keys)
      keys = keys.flatten

      _store_accessors_module.module_eval do
        keys.each do |key|
          define_method("#{key}=") do |value|
            write_store_attribute(store_attribute, key, value)
          end

          define_method(key) do
            read_store_attribute(store_attribute, key)
          end
        end
      end

      self.encrypted_attributes[store_attribute] ||= []
      self.encrypted_attributes[store_attribute] |= keys
    end

    def _store_accessors_module
      @_store_accessors_module ||= begin
        mod = Module.new
        include mod
        mod
      end
    end

  end

  def encrypt_attribute(store_attribute, key, value)
    cipher = ::Gibberish::AES.new(self.aes_key)
    self.send(store_attribute)[key] = cipher.enc(value)
  end

  def decrypt_store(store_attribute, aes_key=nil)
    self.aes_key ||= aes_key
    attribute = initialize_store_attribute("plain_#{store_attribute}")
    cipher = ::Gibberish::AES.new(self.aes_key)
    send(store_attribute).each do |key, value|
      attribute[key] = cipher.dec(send(store_attribute)[key]).force_encoding('UTF-8')
    end
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

    def initialize_store_attribute(store_attribute)
      attribute = send(store_attribute)
      unless attribute.is_a?(ActiveSupport::HashWithIndifferentAccess)
        attribute = IndifferentCoder.as_indifferent_hash(attribute)
        send :"#{store_attribute}=", attribute
      end
      attribute
    end

    class IndifferentCoder # :nodoc:
      def initialize(coder_or_class_name)
        @coder =
          if coder_or_class_name.respond_to?(:load) && coder_or_class_name.respond_to?(:dump)
            coder_or_class_name
          else
            ActiveRecord::Coders::YAMLColumn.new(coder_or_class_name || Object)
          end
      end

      def dump(obj)
        @coder.dump self.class.as_indifferent_hash(obj)
      end

      def load(yaml)
        self.class.as_indifferent_hash @coder.load(yaml)
      end

      def self.as_indifferent_hash(obj)
        case obj
        when ActiveSupport::HashWithIndifferentAccess
          obj
        when Hash
          obj.with_indifferent_access
        else
          ActiveSupport::HashWithIndifferentAccess.new
        end
      end
    end

end