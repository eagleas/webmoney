require File.dirname(__FILE__) + '/../spec_helper'

class Webmoney

  describe Messenger, "class" do

    before(:each) do                                                                                                   
      @wm = webmoney()                                                                                               
    end
    
    it "should create instance and send messages" do
      @wm.messenger.should be_nil
      @wm.send_message(:wmid => @wm.wmid, :subj => 'FIRST', :text => 'BODY')
      @wm.messenger.should be_instance_of(Messenger)
      @wm.send_message(:wmid => @wm.wmid, :subj => 'SECOND', :text => 'SECOUND')
      sleep(3)
    end
    
    # TODO HOW TEST IT FUNCTIONALITY???
    
  end

end
