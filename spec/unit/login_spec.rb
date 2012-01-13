#encoding: utf-8
require 'spec_helper'

describe "login interface" do

  before(:each) do
    @ca = contragent()
  end

  it "return InvalidArgument" do
    lambda { @ca.request(:login,
      :WmLogin_WMID => @ca.wmid,
      :WmLogin_UrlID => 'invalid_rid')
    }.should raise_error(Webmoney::ResultError, "1 InvalidArgument")
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
