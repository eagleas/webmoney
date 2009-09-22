require 'thread'

module Webmoney

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
              # Requeue if fail
              @queue.push(msg) unless result.kind_of?(Hash)
            rescue ResultError, ResponseError => e
              # TODO Replace this to logger call
              # puts "#{e}: #{@webmoney.error} #{@webmoney.errormsg}"

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

    # TODO callback on success send message
    
  end
  
end