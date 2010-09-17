#encoding: utf-8
require 'spec_helper'

describe Time, "class" do
  it "should test time from_ms" do
    time = Time.xmlschema("2006-10-10T17:00:45.383")
    time.strftime('%Y-%m-%d %H:%M:%S').should == '2006-10-10 17:00:45'
  end

  it "should test time from_ms without ending zeros" do
    time = Time.xmlschema("2006-10-10T17:00:45")
    time.strftime('%Y-%m-%d %H:%M:%S').should == '2006-10-10 17:00:45'
  end

end
