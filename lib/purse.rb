#encoding: utf-8
# Support class
module Webmoney
  class Purse < String

    # Parameter: purse - String or Purse

    def initialize(str)
      str = str.to_s unless str.kind_of?(String)
      raise IncorrectPurseError, str unless str =~ /^[BCDEGRUYXZ]\d{12}$/
      super(str)
    end

    def purse; self end

    def self.worker= (worker)
      @@worker = worker
    end

    def self.worker
      @@worker
    end

    # Get WMID for this purse
    def wmid
      # memoize
      @wmid ||=
        begin
          res = @@worker.request(:find_wm, :purse => self, :wmid => "")
          res[:retval] == 1 ? Wmid.new(res[:wmid]) : nil
        end
    end

    # Purse is belong to wmid?
    def belong_to?(wmid)
      self.wmid == Wmid.new(wmid)
    end

  end
end
