module RailsEncryptedStore
  class Railtie < ::Rails::Railtie

    initializer 'rails_encrypted_store.initialize' do
      ActiveSupport.on_load :active_record do
        ::ActiveRecord::Base.send :include, RailsEncryptedStore
        #include RailsEncryptedStore

        #extend ModelAdditions
        #RailsEncryptedStore.insert
      end
    end

  end
end