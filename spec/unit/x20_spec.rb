#encoding: utf-8
require 'spec_helper'

describe "X20 Protocol support request" do

  before(:each) do
    @wm = TestWM.new
  end

  it "should raise error if wmid blank" do
    lambda {@wm.request(:req_payment, :wmid => '', :purse => WmConfig.first['wmr'], :amount => '1', :paymentid => reqn, :clientid => WmConfig.second['wmid'], :description => 'any payment you want', :clientidtype => '1')}.should raise_error(Webmoney::ResultError)
  end

  it "should raise error if purse blank" do
    lambda {@wm.request(:req_payment, :wmid => @wmid, :purse => '', :amount => '1', :paymentid => reqn, :clientid => WmConfig.second['wmid'], :description => 'any payment you want', :clientidtype => '1')}.should raise_error(Webmoney::ResultError)
  end

  it "should raise error if amount blank" do
    lambda {@wm.request(:req_payment, :wmid => @wmid, :purse => WmConfig.first['wmr'], :amount => '', :paymentid => reqn, :clientid => WmConfig.second['wmid'], :description => 'any payment you want', :clientidtype => '1')}.should raise_error(Webmoney::ResultError)
  end
  
  it "should raise error if clientid blank" do
    lambda {@wm.request(:req_payment, :wmid => @wmid, :purse => WmConfig.first['wmr'], :amount => '1', :paymentid => reqn, :clientid => '', :description => 'any payment you want', :clientidtype => '1')}.should raise_error(Webmoney::ResultError)
  end
  
  it "should raise error if clientid type blank" do
    lambda {@wm.request(:req_payment, :wmid => @wmid, :purse => WmConfig.first['wmr'], :amount => '1', :paymentid => reqn, :clientid => WmConfig.second['wmid'], :description => 'any payment you want', :clientidtype => '')}.should raise_error(Webmoney::ResultError)
  end
  
  it "should not raise Webmoney Result Error If you have any money" do
    #!!!!!!!WARNING!!!!!!
    #if got sms, everything ok
    lambda {@wm.request(:req_payment, :wmid => @wmid, :purse => WmConfig.first['wmr'], :amount => '1', :paymentid => reqn, :clientid => WmConfig.second['wmid'], :description => 'any payment you want', :clientidtype => '1')}.should_not raise_error(Webmoney::ResultError)
  end
  
end

describe "X20 Protocol support confirmation" do
  
  before(:each) do
    @wm = TestWM.new
  end
  
  it "should raise Webmoney Result Error if wmid is blank" do
    lambda {@wm.request(:conf_payment, :wmid => '', :purse => WmConfig.first['wmr'], :paymentcode => "1234", :invoiceid => "12332432")}.should raise_error(Webmoney::ResultError)
  end
  
  it "should raise Webmoney Result Error if purse is blank" do
    lambda {@wm.request(:conf_payment, :wmid => @wmid, :purse => WmConfig.first['wmr'], :paymentcode => "1234", :invoiceid => "12332432")}.should raise_error(Webmoney::ResultError)
  end
  
  it "should raise Webmoney Result Error if paymentcode is blank or wrong" do
    lambda {@wm.request(:conf_payment, :wmid => @wmid, :purse => WmConfig.first['wmr'], :paymentcode => "1234", :invoiceid => "12332432")}.should raise_error(Webmoney::ResultError)
  end
end

def reqn
  t = Time.now
  msec = t.to_f.to_s.match(/\.(\d\d)/)[1] rescue '00'
  req = t.strftime('%y%m%d%H%M%S') + msec
  d = req.slice!(0..4)
  return req
end
