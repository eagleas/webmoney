#encoding: utf-8
require 'spec_helper'

describe Webmoney::Wmid, "class" do

  before(:each) do
    @t = Webmoney::Wmid.new('123456789012')
  end

  it "should be kind of Wmid" do
    @t.should be_kind_of(Webmoney::Wmid)
  end

  it "should be string" do
    @t.should == '123456789012'
  end

  it "should permit initialize by integer" do
    Webmoney::Wmid.new(123456789012).should == '123456789012'
  end

  it "should raise error on incorrect wmid" do
    lambda{Webmoney::Wmid.new('abc')}.
      should raise_error(Webmoney::IncorrectWmidError)
  end

end
