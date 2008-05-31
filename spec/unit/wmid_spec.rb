require File.dirname(__FILE__) + '/../spec_helper'

class Webmoney

  describe Wmid, "class" do

    before(:each) do
      @t = Wmid.new('123456789012')
    end

    it "should be kind of Wmid" do
      @t.should be_kind_of(Wmid)
    end

    it "should be string" do
      @t.should == '123456789012'
    end

    it "should permit initialize by integer" do
      Wmid.new(123456789012).should == '123456789012'
    end 

    it "should raise error on incorrect wmid" do
      lambda{Wmid.new('abc')}.
        should raise_error(IncorrectWmidError)
    end 

  end

end
