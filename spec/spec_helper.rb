$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'bundler'
require 'active_record'
require 'rails_encrypted_store'

#Bundler.require(:default, :test)

ActiveRecord::Base.establish_connection({
  adapter: 'sqlite3', 
  database: ':memory:'
})

class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :members do |t|
      t.text :data
    end
  end

  def self.down
    drop_table :members
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    CreateSchema.up
  end

  config.after(:each) do
    ActiveRecord::Base.connection.execute('Delete from members')
  end

  config.after(:suite) do
    CreateSchema.down
  end
end