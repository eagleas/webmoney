# Support class
class Webmoney
  class Wmid < String
    
    def initialize(str)
      str = str.to_s unless str.kind_of?(String)
      raise IncorrectWmidError, ': ' + str.to_s unless str =~ /^\d{12}$/
      super(str)
    end
    
    def wmid; self end
    
  end
end
