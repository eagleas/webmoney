#encoding: utf-8
require 'spec_helper'

describe 'filter_str' do

  let(:test) { "ényképek-0001.xls" }

  it "default behavior" do
    @wm = TestWM.new
    if  String.new.respond_to?(:encode)
      lambda { @wm.filter_str(test) }.should raise_error(Encoding::UndefinedConversionError)
    else
      lambda { @wm.filter_str(test) }.should raise_error(Iconv::IllegalSequence)
    end
  end

  it "with force_encoding" do
    @wm = TestWM.new(:force_encoding => true)
    input, output = @wm.filter_str(test)
    output.should == "nykpek-0001.xls"
    input.should  == "nykpek-0001.xls"
  end

  it "should send message with ignore characters" do
    @wm = TestWM.new(:force_encoding => true)
    result = @wm.request( :send_message,
      :wmid => @wm.wmid,
      :subj => 'Wörter',
      :text => 'ényképek-0001.xls')
    result.should be_kind_of(Hash)
    result[:id].should match(/^\d*$/)
    ((result[:date] + 60) > Time.now).should be_true
  end

end
