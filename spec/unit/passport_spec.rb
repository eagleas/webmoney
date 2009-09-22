require File.dirname(__FILE__) + '/../spec_helper'

module Webmoney

  describe Passport, "class" do

    before(:each) do                                                                                                   
      @wm = webmoney()                                                                                               
    end
    
    def make_request(wmid=nil)      #   :nodoc:
      test_wmid = wmid || @wm.wmid
      x = Builder::XmlMarkup.new
      x.request do
        x.wmid @wm.wmid
        x.passportwmid test_wmid
        x.sign @wm.send(:sign, @wm.wmid + test_wmid)
        x.params { x.dict 0; x.info 1; x.mode 0 }
      end
      x.target!
    end
    
    it "should return empty on incorrect xml" do
      Passport.new('<response/>').should == ''
    end

    it "should return Passport instance" do
      Passport.new(@wm.send(:https_request, :get_passport, make_request)).should be_instance_of(Passport)
    end
    
    it "should return correct data" do
      wmid = '000000000007'
      p = Passport.new(@wm.send(:https_request, :get_passport, make_request(wmid)))
      p.wmid.should == wmid
      p.attestat.should == Webmoney::Passport::REGISTRATOR
      p.created_at.strftime('%Y-%m-%d %H:%M:%S').should == '2004-02-25 21:54:01'
      
      wmid = '370860915669'
      p = Passport.new(@wm.send(:https_request, :get_passport, make_request(wmid)))
      p.wmid.should == wmid
      p.attestat.should == Webmoney::Passport::ALIAS
      p.created_at.strftime('%Y-%m-%d %H:%M:%S').should == '2006-04-19 10:16:30'
    end

  end

end
