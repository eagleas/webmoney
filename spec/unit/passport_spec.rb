require File.dirname(__FILE__) + '/../spec_helper'

module Webmoney

  describe Passport, "class" do

    before(:each) do                                                                                                   
      @wm = webmoney()                                                                                               
    end
    
    it "should return Passport instance" do
      Passport.new(@wm.wmid).should be_instance_of(Passport)
    end

    it "request result get_passport should be hash with data" do
      wmid = '000000000007'
      created_at = Time.at(1077735241.37)
      res = @wm.request(:get_passport, :wmid => wmid, :dict => 1)
      res.should == {
        :full_access=>false,
        :wmids => {
          wmid => {
            :created_at=>Time.at(1077733193.353)
          }
        },
        :attestat=>{
          :regcid=>"10",
          :locked=>"1",
          :recalled=>"0",
          :cid=>"103453",
          :admlocked=>"0",
          :created_at=>created_at,
          :datecrt=>"2004-02-25T21:54:01.370",
          :regnickname=>"WM Passport Service /Центр аттестации/",
          :regwmid=>"464889785562",
          :attestat=>150,
          :tid=>"150",
          :datediff=>(Date.today - created_at.send(:to_date)).to_s
        },
        :userinfo=>{
          :locked=>"0",
          :ctype=>"1",
          :citid=>"12918",
          :cap_owner=>"0",
          :region=>"Москва",
          :countryid=>"195",
          :city=>"Москва",
          :pasdoc=>"0",
          :nickname=>"Арбитр",
          :country=>"Россия",
          :inndoc=>"0",
          :email=>"", :iname=>"", :inn=>"", :okonx=>"", :bik=>"", :pbywhom=>"", :phonemobile=>"", :rcountry=>"",
          :bmonth=>"", :jadres=>"", :okpo=>"", :bday=>"", :pnomer=>"", :bankname=>"", :pcountry=>"", :pcountryid=>"",
          :jcountryid=>"", :ks=>"", :infoopen=>"", :icq=>"", :byear=>"", :oname=>"", :osnovainfo=>"", :dirfio=>"",
          :pdate=>"", :bplace=>"", :rs=>"", :rcity=>"", :adres=>"", :phone=>"", :buhfio=>"", :radres=>"", :fname=>"",
          :phonehome=>"", :jcity=>"", :name=>"", :pcity=>"", :jstatus=>"", :fax=>"", :zipcode=>"", :rcountryid=>"",
          :web=>"", :jzipcode=>"", :jcountry=>""},
        :directory=>{
          :ctype=>{
            1=>"Частное лицо",
            2=>"Юридическое лицо"
          },
          :jstatus=>{
            20=>"Директор юридического лица",
            21=>"Бухгалтер юридического лица",
            22=>"Представитель юридического лица",
            23=>"ИП"
          },
          :types=>{
            100=>"Аттестат псевдонима",
            110=>"Формальный аттестат",
            120=>"Начальный аттестат",
            130=>"Персональный аттестат",
            135=>"Аттестат продавца",
            136=>"Аттестат Capitaller",
            140=>"Аттестат разработчика",
            150=>"Аттестат регистратора",
            170=>"Аттестат Гаранта",
            190=>"Аттестат сервиса WMT",
            200=>"Аттестат сервиса WMT",
            300=>"Аттестат Оператора"
          }
        }
      }
    end

    it "should return userinfo attributes with checked/locked" do
      wmid = '000000000007'
      p = Passport.new(wmid)
      p.userinfo[:adres].should be_empty
      p.userinfo[:adres].checked.should be_true
      p.userinfo[:adres].locked.should be_true
      p.userinfo[:inn].should be_empty
      p.userinfo[:inn].checked.should be_false
      p.userinfo[:inn].locked.should be_true
    end

    it "should return correct fields" do
      wmid = '000000000007'
      p = Passport.new(wmid)
      p.wmid.should == wmid
      p.attestat[:attestat].should == Webmoney::Passport::REGISTRATOR
      p.attestat[:created_at].strftime('%Y-%m-%d %H:%M:%S').should == '2004-02-25 21:54:01'
      p.full_access.should be_false
      
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
