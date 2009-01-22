require 'thread'

class Webmoney

  class Messenger
    
    def initialize(owner)
      @webmoney = owner
      @queue = Queue.new
      @thread = Thread.new(@queue) do |q|
        loop do
          msg = q.pop
          unless msg.nil?
            begin
              result = @webmoney.request(:send_message, msg)
              @queue.push(msg) unless result.kind_of?(Hash)
            rescue ResultError
              puts "ResultError: #{@webmoney.error} #{@webmoney.errormsg}"
              # Silent drop message
            rescue ResponseError
              puts "ResponseError: #{@webmoney.error}"
              # Requeue message
              @queue.push(msg)
            end
          end
        end
      end
    end
    
    def push(msg)
      @queue.push(msg)
    end
    
  end
  
end