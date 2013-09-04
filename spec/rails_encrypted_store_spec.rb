require 'spec_helper'

describe RailsEncryptedStore do

  let(:member_class) {
    Class.new(ActiveRecord::Base) do
      self.table_name = 'members'
      include RailsEncryptedStore
      
      def data_key
        "2sZ6acBEcekBDrvVUfx2TZK3MC"
      end
    end
  }

  it "allows you to specify attributes to be encrypted" do
    member_class.encrypted_store :data, accessors: [:name, :email, :phone]
    member_class.stored_attributes[:data].should == [:name, :email, :phone]
  end

  it "allows you to set and get attributes values" do
    member_class.encrypted_store :data, accessors: [:name, :email, :phone]
    member = member_class.new(name: 'Robin Masters', email: 'robin@masters.com')
    member.phone = '12345678'

    member.name.should == 'Robin Masters'
    member.email.should == 'robin@masters.com'
    member.phone.should == '12345678'
  end

  it "transparently stores attributes encrypted in db" do
    member_class.encrypted_store :data, accessors: [:name, :email, :phone]
    member_class.create(name: 'Robin Masters', email: 'robin@masters.com', phone: '12345678')
    member = member_class.last

    member.data.should_not be_nil
    member.data[:name].should_not == 'Robin Masters'
    member.name.should be_nil
  end

  it "allows you to decrypt and get attributes values" do
    member_class.encrypted_store :data, accessors: [:name, :email, :phone]
    member_class.create(name: 'Robin Masters', email: 'robin@masters.com', phone: '12345678')
    member = member_class.last
    member.decrypt_store(:data)

    member.name.should == 'Robin Masters'
    member.email.should == 'robin@masters.com'
    member.phone.should == '12345678'
  end

  it "allows you to update attributes values" do
    member_class.encrypted_store :data, accessors: [:name, :email, :phone]
    member = member_class.create(name: 'Robin Masters', email: 'robin@masters.com', phone: '12345678')
    member.update_attributes(name: 'Thomas Magnum', email: 'thomas@magnum.com', phone: '87654321')
    member = member_class.last
    member.decrypt_store(:data)

    member.name.should == 'Thomas Magnum'
    member.email.should == 'thomas@magnum.com'
    member.phone.should == '87654321'
  end

end