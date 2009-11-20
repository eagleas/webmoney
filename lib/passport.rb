# Class for store attestat information
module Webmoney
  class Passport < Wmid

    # Attestate types
    ALIAS       = 100
    FORMAL      = 110
    START       = 120
    PERSONAL    = 130
    PAYER       = 135
    CAPITALLER  = 136
    DEVELOPER   = 140
    REGISTRATOR = 150
    GARANT      = 170
    SERVICE     = 190
    SERVICE2    = 200
    OPERATOR    = 300

    def self.worker= (worker)
      @@worker = worker
    end

    def self.worker
      @@worker
    end

    # memoize data

    def attestat
      @attestat ||= getinfo[:attestat]
    end

    def full_access
      @full_access = getinfo[:full_access]
    end

    protected

    def getinfo
      info = @@worker.request(:get_passport, :wmid => self)
      @attestat = info[:attestat]
      @full_access = info[:full_access]
      info
    end

  end
end