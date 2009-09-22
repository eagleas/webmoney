require File.dirname(__FILE__) + '/../spec_helper'

module Webmoney

  describe Webmoney, "class" do

    before(:each) do                                                                                                   
      @wm = webmoney()
    end

    it "should be classic" do
      @wm.classic?.should be_true
    end
    
    it "should return reqn" do
      t1 = @wm.send(:reqn)
      sleep(0.1)
      t2 = @wm.send(:reqn)
      t1.should match(/^\d{16}$/)
      (t2 > t1).should be_true
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
      r = @wm.send(:https_request, :check_sign, '<w3s.request/>')
      doc = Hpricot.XML(r.gsub(/w3s\.response/,'w3s_response'))
      doc.at('w3s_response').should_not be_nil
    end

    it"should raise error on bad response" do
      lambda { @wm.send(:https_request, 
        'https://w3s.wmtransfer.com/asp/XMLUnexistantIface.asp', '<w3s.request/>')}.
        should raise_error(RequestError)
      @wm.error.should == '404'
      @wm.errormsg.should match(/^<!DOCTYPE HTML PUBLIC/)
    end

    it "should parse retval and raise error" do
      lambda { @wm.request(:send_message, :wmid => '')}.should raise_error(ResultError)
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
      @wm.request(:check_sign, 
        :wmid => @wm.wmid, :plan => plan, :sign => @wm.send(:sign, real_plan )).
        should be_true
    end
    
    it "should parse retval and raise error on broken get_passport" do
      lambda { @wm.request(:get_passport, :wmid => '') }.should raise_error(ResultError)
      @wm.error.should == 2
      @wm.errormsg.should match(%r{неверно указан проверяемый WMID})
    end

    it "should get_passport" do
      @wm.request(:get_passport, :wmid => @wm.wmid).should be_instance_of(Passport)
    end

    it "should raise exception on bad WMID" do
      lambda {@wm.request(:get_passport, :wmid => '111')}.should raise_error(Webmoney::ResultError)
    end

    it "should raise exception on non existent WMID" do
      lambda {@wm.request(:get_passport, :wmid => '012345678901')}.should raise_error(Webmoney::NonExistentWmidError)
    end

    it "should return correct BL" do
      wmid = '370860915669'
      @wm.request(:bussines_level, :wmid => wmid).should == 0

      wmid = Wmid.new '000000000007'
      bl = @wm.request(:bussines_level, :wmid => wmid)
      (bl > 1000).should be_true
    end
    
    it "should send message" do
      result = @wm.request(:send_message, 
        :wmid => @wm.wmid, :subj => 'Текст', :text => 'Тело <b>сообщения</b>')
      result.should be_kind_of(Hash)
      result[:id].should match(/^\d*$/)
      ((result[:date] + 60) > Time.now).should be_true
    end
    
    it "should raise error on undefined xml func" do
      lambda { @wm.request(:unexistent_interface) }.should raise_error(::NotImplementedError)
    end

  end

end