#encoding: utf-8
require 'spec_helper'

describe "check_user (x19) interface" do

  before(:each) do
    @wm = webmoney()
    @valid_params = {
      :operation => {
        :type => 2,
        :amount => 100,
        :pursetype => "WMZ"
      },
      :userinfo => {
        :wmid => WmConfig.second['wmid'],
        :iname => WmConfig.second['iname'],
        :fname => WmConfig.second['fname']
      }
    }
  end

  it "retval 0 for valid wmid+iname+fname" do
    result = @wm.request(:check_user, @valid_params)
    result[:retval].should == 0
  end

  it "retval 404 for invalid wmid+iname+fname" do
    @valid_params[:userinfo][:fname] = "invalid"
    result = @wm.request(:check_user, @valid_params)
    result[:retval].should == 404
  end

end
