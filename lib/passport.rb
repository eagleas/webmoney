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

    attr_reader :attestat

    def self.worker= (worker)
      @@worker = worker
    end

    def self.worker
      @@worker
    end

    def attestat
      # memoize
      @attestat ||= @@worker.request(:get_passport, :wmid => self)
    end

  end
end