#encoding: utf-8
require 'spec_helper'

describe "balance (x9) interface" do

  before(:each) do
    @wm = webmoney()
  end

  it "result should have purse list" do
    result = @wm.request(:balance)
    result[:purses].should_not be_empty
  end

  it "retval should be zero" do
    result = @wm.request(:balance)
    result[:retval].should == 0
  end


end
