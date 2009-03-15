require File.dirname(__FILE__) + '/../spec_helper'

class Webmoney

  describe Messenger, "class" do

    before(:each) do                                                                                                   
      @wm = webmoney()                                                                                               
    end
    
    it "should create instance" do
      @wm.messenger.should be_nil
      @wm.send_message(:wmid => @wm.wmid, :subj => 'FIRST', :text => 'BODY')
      @wm.messenger.should be_instance_of(Messenger)
    end
    
    it "should call request(:send_message) twice" do
      params = { :wmid => @wm.wmid, :subj => 'FIRST', :text => 'BODY' }
      @wm.should_receive(:request).
        with(:send_message, params).twice().and_return({:test => 'test'})
      @wm.send_message(params)
      @wm.send_message(params)
    end

  end

end
