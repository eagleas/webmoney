#encoding: utf-8
require 'thread'

module Webmoney

  class Messenger

    attr_reader :thread

    def initialize(owner, &logger)
      @webmoney = owner
      @queue = Queue.new
      @thread = Thread.new(@queue) do |q|
        loop do
          msg = q.pop
          unless msg.nil?
            begin
              result = @webmoney.request(:send_message, msg)
              logger.call(msg, result)
              # Requeue message on fail
              @queue.push(msg) unless result.kind_of?(Hash)
            rescue ResultError => e
              logger.call(msg, e)
              # Requeue message
              @queue.push(msg)
            end
          end
          sleep(0.2)
        end
      end
    end
    
    def push(msg)
      @queue.push(msg)
    end

    # TODO callback on success send message
    
  end
  
end