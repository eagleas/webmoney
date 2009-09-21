require File.dirname(__FILE__) + '/../spec_helper'

class Webmoney

  describe Messenger, "class" do

    before(:each) do                                                                                                   
      @wm = webmoney()
      @params = { :wmid => @wm.wmid, :subj => 'FIRST', :text => 'BODY' }
    end
    
    it "should create instance" do
      @wm.messenger.should be_nil
      @wm.send_message(@params)
      @wm.messenger.should be_instance_of(Messenger)
    end

    it "should send with logger call" do
      self.should_receive(:log_it).once()
      logger = Proc.new do |msg, result|
        case result
        when Hash
          log_it "Message #{msg.inspect} sended in:#{result[:date]} with id:#{result[:id]}"
        else
          log_it "Error sent message #{msg.inspect}: #{result.message}"
        end
      end
      @wm.messenger = Messenger.new(@wm, &logger)
      @wm.send_message(@params)
      sleep(2)
    end

    it "should call request(:send_message) twice" do
      @wm.should_receive(:request).
        with(:send_message, @params).twice().and_return({:test => 'test'})
      2.times {@wm.send_message(@params)}
      sleep(2)
    end

  end

end
