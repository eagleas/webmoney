#encoding: utf-8
require 'spec_helper'

describe 'filter_str' do

  let(:test) { "ényképek-0001.xls" }

  it "default behavior" do
    @wm = TestWM.new
    lambda { @wm.filter_str(test)}.should raise_error(Iconv::IllegalSequence)
  end

  it "with force_encoding" do
    @wm = TestWM.new(:force_encoding => true)
    input, output = @wm.filter_str(test)
    output.should == Iconv.iconv('CP1251//IGNORE', 'UTF-8', test)[0]
    input.should == Iconv.iconv('UTF-8', 'CP1251', output)[0]
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
