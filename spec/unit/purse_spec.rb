require File.dirname(__FILE__) + '/../spec_helper'

module Webmoney

  describe Purse, "class" do

    before(:all) do
      # initialize worker
      webmoney
    end

    before(:each) do
      @t = Purse.new('Z136894439563')
    end

    it "should be kind of Wmid" do
      @t.should be_kind_of(Purse)
    end

    it "should be string" do
      @t.should == 'Z136894439563'
    end

    it "should raise error on incorrect" do
      lambda{ Purse.new('X123456789012') }.
        should raise_error(IncorrectPurseError)
    end

    it "should return wmid" do
      @t.wmid.should == '405424574082'
    end

  end

end
