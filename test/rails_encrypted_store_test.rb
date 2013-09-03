require File.expand_path('../test_helper', __FILE__)

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_tables
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :secrets do |t|
        t.text :encrypted_data
      end
    end
  end
end

# The table needs to exist before defining the class
create_tables

ActiveRecord::MissingAttributeError = ActiveModel::MissingAttributeError unless defined?(ActiveRecord::MissingAttributeError)


class Secret < ActiveRecord::Base

  include RailsEncryptedStore

  encrypted_store :encrypted_data, accessors: [:author, :message]

  def aes_key
    self.encrypted_data_will_change!
    "2sZ6acBEcekBDrvVUfx2TZK3MC"
  end

end


class ActiveRecordTest < Test::Unit::TestCase

  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_tables
    @secret = Secret.create author: 'Heiner Sameisky', message: 'Lorem ipsum dolor sit amet'
  end

  # def test_should_create_secret
  #   @secret = Secret.create author: 'Heiner Sameisky', message: 'Lorem ipsum dolor sit amet'
  #   #@secret = Secret.find @secret.id
  # end

  def test_secret_is_encrypted
    @secret = Secret.first
    assert_not_nil @secret.encrypted_data
    assert_nil @secret.author
    assert_not_equal 'Heiner Sameisky', @secret.encrypted_data[:author]
  end

  def test_secret_can_be_decrypted
    @secret = Secret.first
    @secret.decrypt_store(:encrypted_data)
    assert_not_nil @secret.author
    assert_equal 'Heiner Sameisky', @secret.author
  end


end