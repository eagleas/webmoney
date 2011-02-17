#encoding: utf-8
require 'spec_helper'

describe "trust (x15) interfaces" do

  before(:each) do
    @wm = webmoney()
  end

  it ":trust_me should return hash" do
    wmid = WmConfig.second['wmid']
    result = @wm.request(:trust_me, :wmid => wmid)
    [:count, :invoices, :transactions, :balance, :history].each do |key|
      result.should have_key(key)
    end
  end

  it ":i_trust should return hash too" do
    result = @wm.request(:i_trust)
    [:count, :invoices, :transactions, :balance, :history].each do |key|
      result.should have_key(key)
    end
  end

end
