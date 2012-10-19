#encoding: utf-8
require 'spec_helper'
require 'date'

describe Webmoney::Passport, "class" do

  before(:each) do
    @wm = webmoney()
  end

  it "should return Passport instance" do
    Webmoney::Passport.new(@wm.wmid).should be_instance_of(Webmoney::Passport)
  end

  # If you get Webmoney::NonExistentWmidError, visit into browser
  # http://passport.webmoney.ru/asp/CertView.asp?wmid=000000000001
  # resolve captcha and retry

  it "request result get_passport should be hash with data" do
    wmid = '000000000007'
    res = @wm.request(:get_passport, :wmid => wmid, :dict => 1)
    res[:full_access].should be_false
    res[:wmids][wmid][:created_at].should be_a(Time)
    res[:attestat][:created_at].should be_a(Time)
    [:regcid, :locked, :recalled, :cid, :admlocked, :created_at, :datecrt, :regnickname,
      :regwmid, :attestat, :tid, :datediff].each do |key|
      res[:attestat].should have_key(key)
    end

    res[:userinfo].should have_key(:city)
    res[:directory].should have_key(:jstatus)
    res[:directory][:jstatus].should have_key(20)

  end

  it "should return userinfo attributes with checked/locked" do
    wmid = '000000000007'
    p = Webmoney::Passport.new(wmid)
    p.userinfo[:adres].should be_empty
    p.userinfo[:adres].checked.should be_true
    p.userinfo[:adres].locked.should be_true
    p.userinfo[:inn].should be_empty
    p.userinfo[:inn].checked.should be_false
    p.userinfo[:inn].locked.should be_true
  end

  it "should return correct fields" do
    wmid = '000000000007'
    p = Webmoney::Passport.new(wmid)
    p.wmid.should == wmid
    p.attestat[:attestat].should == Webmoney::Passport::REGISTRATOR
    p.attestat[:created_at].strftime('%Y-%m-%d %H:%M:%S').should == '2004-02-25 21:54:01'
    p.full_access.should be_false

    wmid = '370860915669'
    p = Webmoney::Passport.new(wmid)
    p.wmid.should == wmid
    p.attestat[:attestat].should == Webmoney::Passport::ALIAS
    p.attestat[:created_at].strftime('%Y-%m-%d %H:%M:%S').should == '2006-04-19 10:16:30'

    wmid = '210971342927'
    p = Webmoney::Passport.new(wmid)
    p.attestat.should_not be_nil
  end

  it "should raise exception on bad WMID" do
    lambda {@wm.request(:get_passport, :wmid => '111')}.should raise_error(Webmoney::ResultError)
  end

  it "should raise exception on non existent WMID" do
    @wm.stub!(:http_request).and_return("<?xml version='1.0' encoding='windows-1251'?><response retval='0'><fullaccess>0</fullaccess><certinfo wmid='012345678901'/><retdesc>WMID not found</retdesc></response>")
    lambda {@wm.request(:get_passport, :wmid => '012345678901')}.should raise_error(Webmoney::NonExistentWmidError)
  end

  it "should raise exception on blank response" do
    @wm.stub!(:http_request).and_return(nil)
    lambda {@wm.request(:get_passport, :wmid => '012345678901')}.should raise_error(Webmoney::NonExistentWmidError)
  end

  it "should have wmids" do
    passport = Webmoney::Passport.new(@wm.wmid, :mode => 1)
    passport.wmids.should be_instance_of(Hash)
    passport.wmids.has_key?(@wm.wmid).should be_true
    passport.wmids[@wm.wmid].should be_instance_of(Hash)
  end
end
