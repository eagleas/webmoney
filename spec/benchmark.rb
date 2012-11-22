#!/usr/bin/env ruby

require 'benchmark'
require "#{File.expand_path File.dirname(__FILE__)}/spec_helper"

@wm = TestWM.new
n = 100
puts Benchmark.measure {
  n.times do
    @wm.send(:sign, 'abc123')
  end
}
