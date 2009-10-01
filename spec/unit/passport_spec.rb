require File.dirname(__FILE__) + '/../spec_helper'

module Webmoney

  describe Passport, "class" do

    before(:each) do                                                                                                   
      @wm = webmoney()                                                                                               
    end
    
    it "should return Passport instance" do
      Passport.new(@wm.wmid).should be_instance_of(Passport)
    end

    it "request result get_passport should be Hash" do
      @wm.request(:get_passport, :wmid => @wm.wmid).should be_instance_of(Hash)
    end
    
    it "should return correct data" do
      wmid = '000000000007'
      p = Passport.new(wmid)
      p.wmid.should == wmid
      p.attestat[:attestat].should == Webmoney::Passport::REGISTRATOR
      p.attestat[:created_at].strftime('%Y-%m-%d %H:%M:%S').should == '2004-02-25 21:54:01'
      
      wmid = '370860915669'
      p = Passport.new(wmid)
      p.wmid.should == wmid
      p.attestat[:attestat].should == Webmoney::Passport::ALIAS
      p.attestat[:created_at].strftime('%Y-%m-%d %H:%M:%S').should == '2006-04-19 10:16:30'
    end

    it "should raise exception on bad WMID" do
      lambda {@wm.request(:get_passport, :wmid => '111')}.should raise_error(Webmoney::ResultError)
    end

    it "should raise exception on non existent WMID" do
      lambda {@wm.request(:get_passport, :wmid => '012345678901')}.should raise_error(Webmoney::NonExistentWmidError)
    end

  end

end
