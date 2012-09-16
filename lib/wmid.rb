#encoding: utf-8
# Support class
module Webmoney
  class Wmid < String

    # Parameter: wmid - String or Wmid

    def initialize(str)
      str = str.to_s unless str.kind_of?(String)
      raise IncorrectWmidError, str unless str =~ /^\d{12}$/
      super(str)
    end

    def wmid; self end

  end
end
