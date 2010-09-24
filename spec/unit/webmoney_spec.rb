#encoding: utf-8
require 'spec_helper'

describe Webmoney, "class" do

  before(:each) do
    @wm = TestWM.new
  end

  it "should be classic" do
    @wm.should be_classic # @wm.classic? == true
  end

  it "should return reqn" do
    t1 = @wm.send(:reqn)
    sleep(0.1)
    t2 = @wm.send(:reqn)
    t1.should match(/^\d{16}$/)
    (t2 > t1).should be_true
  end

  it "should correct prepare interfaces urls" do
    wm = TestWM.new :wmid => WmConfig.first['wmid'], :key => nil
    wm.should_not be_classic
    wm.interfaces[:balance].class.should == URI::HTTPS
    # converted to light-auth version
    wm.interfaces[:balance].to_s.should == 'https://w3s.wmtransfer.com/asp/XMLPursesCert.asp'
    # non-converted to light-auth version
    wm.interfaces[:get_passport].to_s.should == 'https://passport.webmoney.ru/asp/XMLGetWMPassport.asp'
  end

  it "should correct reqn" do
    Time.stub!(:now).and_return(Time.at(1244704683.69677))
    @wm.send(:reqn).should == '2009061111180369'
  end

  it "should correct reqn with zero microsec" do
    Time.stub!(:now).and_return(Time.at(1244704683))
    @wm.send(:reqn).should == '2009061111180300'
  end

  it "should raise error on incorrect arg" do
    lambda { @wm.send(:request, :check_sign, 1) }.
      should raise_error(ArgumentError)
  end

  it "should send request" do
    doc = Nokogiri.XML(@wm.send(:https_request, :check_sign, '<w3s.request/>'))
    doc.root.should_not be_nil
  end

  it"should raise error on bad response" do
    lambda { @wm.send(:https_request,
      'https://w3s.wmtransfer.com/asp/XMLUnexistantIface.asp', '<w3s.request/>')}.
      should raise_error(Webmoney::RequestError)
    @wm.error.should == '404'
    @wm.errormsg.should match(/^<!DOCTYPE HTML PUBLIC/)
  end

  it "should parse retval and raise error" do
    lambda { @wm.request(:send_message, :wmid => '')}.should raise_error(Webmoney::ResultError)
    @wm.error.should == -2
    @wm.errormsg.should match(%r{value of w3s.request/message/receiverwmid  is incorrect})
  end

  it "should sign string" do
    @wm.send(:sign, 'Test123').should match(/^[0-9a-f]{132}$/)
  end

  it "should return nil on sign empty string" do
    @wm.send(:sign, '').should be_nil
  end

  it "should check_sign" do
    plan = 'test123'
    @wm.request(:check_sign,
      :wmid => @wm.wmid, :plan => plan, :sign => @wm.send(:sign, plan)).
      should be_true
  end

  it "should check_sign broken" do
    plan = 'test123'
    @wm.request(:check_sign,
      :wmid => @wm.wmid, :plan => plan, :sign => 'abcd').
      should be_false
  end

  it "should check_sign with specials" do
    plan = '<test>текст</test>'
    real_plan = Iconv.conv('CP1251', 'UTF-8', plan)
    begin
    @wm.request(:check_sign,
      :wmid => @wm.wmid,
      :plan => plan,
      :sign => @wm.send(:sign, real_plan )
    ).should be_true
    end
  end

  it "should parse retval and raise error on broken get_passport" do
    lambda { @wm.request(:get_passport, :wmid => '') }.should raise_error(Webmoney::ResultError)
    @wm.error.should == 2
    @wm.errormsg.should match(%r{неверно указан проверяемый WMID})
  end

  it "should raise exception on bad WMID" do
    lambda {@wm.request(:get_passport, :wmid => '111')}.should raise_error(Webmoney::ResultError)
  end

  it "should raise exception on non existent WMID" do
    lambda {@wm.request(:get_passport, :wmid => '012345678901')}.should raise_error(Webmoney::NonExistentWmidError)
  end

  it "should create transaction" do
    # TODO @wm.request( :create_transaction, ...)
  end

  it "should return correct BL" do
    wmid = '370860915669'
    @wm.request(:bussines_level, :wmid => wmid).should == 0

    wmid = Webmoney::Wmid.new '000000000007'
    bl = @wm.request(:bussines_level, :wmid => wmid)
    (bl > 1000).should be_true
  end

  it "should send message" do
    result = @wm.request( :send_message,
      :wmid => @wm.wmid,
      :subj => 'Текст',
      :text => 'Тело <b>сообщения</b>')
    result.should be_kind_of(Hash)
    result[:id].should match(/^\d*$/)
    ((result[:date] + 60) > Time.now).should be_true
  end

  it "should return operation history" do
    # TODO
    #@mywm.request(:operation_history,
    # :purse => "Z161888783954",
    # :tranid => 148696631,
    # :wminvid => 148613215,
    # :orderid => 1,
    # :datestart => Date.today() - 1,
    # :datefinish => Date.today() + 1
    #)
  end

  it "should create transaction" do
    # TODO @wm.request( :create_transaction, ...)
  end

  it "should raise error on undefined xml func" do
    lambda { @wm.request(:unexistent_interface) }.should raise_error(::NoMethodError)
  end

  describe "invoice" do
    before(:each) do
      @wm = webmoney()
      @ca = contragent()
      # create invoice
      @invoice = @ca.request(:create_invoice,
        :orderid => 1,
        :amount => 1,
        :customerwmid => @wm.wmid,
        :storepurse => WmConfig.second['wmz'],
        :desc => "Test invoice",
        :address => "Address"
      )
    end

    it "should be created" do
      @invoice[:retval].should == 0
      @invoice[:state].should == 0
      @invoice[:orderid].should == 1
      @invoice[:ts].should > 0
      @invoice[:id].should > 0
    end

    it "should be in state 0 (not paid)" do
      res = @ca.request(:outgoing_invoices,
        :purse => WmConfig.second['wmz'],
        :wminvid => @invoice[:id],
        :orderid => @invoice[:orderid],
        :customerwmid => @wm.wmid,
        :datestart => @invoice[:created_at],
        :datefinish => @invoice[:created_at]
      )
      res[:retval].should == 0
      res[:invoices].length.should == 1
      res[:invoices][0][:state].should == 0
      res[:invoices][0][:amount].should == 1
    end
  end

  describe "login interface" do

    before(:each) do
      @ca = contragent()
    end

    it "return InvalidArgument" do
      lambda { @ca.request(:login,
        :WmLogin_WMID => @ca.wmid,
        :WmLogin_UrlID => 'invalid_rid')
      }.should raise_error(Webmoney::RequestError, "1 InvalidArgument")
      @ca.error.should == 1
      @ca.errormsg.should == 'InvalidArgument'
    end

    it "return InvalidTicket" do
      lambda { @ca.request(:login,
        :WmLogin_WMID => @ca.wmid,
        :WmLogin_UrlID => @ca.rid,
        :WmLogin_Ticket => 'XVWuooAEOJ0gG5NyDXJ0Zu0GffroqkG7APNKFmCAzA7XNVSx',
        :WmLogin_AuthType => 'KeeperLight',
        :remote_ip => '127.0.0.1'
        )
      }.should raise_error(Webmoney::ResultError)
      @ca.error.should == 2
      @ca.errormsg.should == 'FalseTicket'
    end
  end

end
