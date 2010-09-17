#encoding: utf-8
require 'spec_helper'

describe Webmoney::Purse, "class" do

  before(:all) do
    # initialize worker
    @wm = TestWM.new
  end

  before(:each) do
    @t = Webmoney::Purse.new('Z136894439563')
  end

  it "should return 111111111111 wmid for Z111111111111 purse" do
    t = Webmoney::Purse.new("Z111111111111")
    t.wmid.should == '111111111111'
  end

  it "should be kind of Wmid" do
    @t.should be_kind_of(Webmoney::Purse)
  end

  it "should be string" do
    @t.should == 'Z136894439563'
  end

  it "should raise error on incorrect" do
    lambda{ Webmoney::Purse.new('X123456789012') }.
      should raise_error(Webmoney::IncorrectPurseError)
  end

  it "should return wmid" do
    @t.wmid.should == '128984249415'
  end

  it "should return true" do
    @wm.should_receive(:request).with(:find_wm, :purse => @t, :wmid => '').and_return(:retval=>1, :wmid => '128984249415')
    @t.belong_to?('128984249415').should be_true
  end

  it "should return false" do
    @wm.should_receive(:request).with(:find_wm, :purse => @t, :wmid => '').and_return(:retval=>0, :wmid => '128984249415')
    @t.belong_to?('123456789012').should be_false
  end

  context "memoize" do

    before(:each) { @t.wmid }

    it "it" do
      @wm.should_not_receive(:request).with(:find_wm, :purse => @t)
      @t.belong_to?('128984249415').should be_true
    end

  end

end
