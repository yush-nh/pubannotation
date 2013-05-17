require 'spec_helper'

describe Insann do
  describe 'get_hash' do
    before do
      @annset = FactoryGirl.create(:annset, :user => FactoryGirl.create(:user))
      @doc = FactoryGirl.create(:doc, :sourcedb => 'sourcedb', :sourceid => 1, :serial => 1, :section => 'section', :body => 'doc body')
      @catann = FactoryGirl.create(:catann, :annset => @annset, :doc => @doc)
      @insann = FactoryGirl.create(:insann,
        :hid => 'hid',
        :instype => 'instype',
        :insobj => @catann,
        :annset => @annset
      )
      @get_hash = @insann.get_hash
    end
    
    it 'should set hid as id' do
      @get_hash[:id].should eql(@insann[:hid])
    end
    
    it 'should set instype as type' do
      @get_hash[:type].should eql(@insann[:instype])
    end
    
    it 'should set hid as object' do
      @get_hash[:object].should eql(@catann[:hid])
    end
  end
end