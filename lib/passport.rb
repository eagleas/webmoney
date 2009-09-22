require 'hpricot'

# Class for store attestat information
module Webmoney
  class Passport < Wmid

    # doc - Hpricot::Doc or xml-string
    def initialize(doc)
      doc = Hpricot.XML(doc) unless doc.kind_of?(Hpricot::Doc)
      root = doc.at('/response')
      if root && root['retval'] && root['retval'].to_i == 0
        super(doc.at('/response/certinfo')['wmid'])
        raise NonExistentWmidError unless doc.at('/response/certinfo/attestat')
        tid = doc.at('/response/certinfo/attestat/row')['tid'].to_i
        recalled = doc.at('/response/certinfo/attestat/row')['recalled'].to_i
        locked = doc.at('/response/certinfo/userinfo/value/row')['locked'].to_i
        @attestat = ( recalled + locked > 0) ? ALIAS : tid
        @created_at = Time.xmlschema(doc.at('/response/certinfo/attestat/row')['datecrt'])

        # TODO more attestat fields...

        # Make all instance variables readable
        instance_variables.each do |n| 
          class << self; self; end.instance_eval {
            attr_reader n.sub(/^@/, '')
          }
        end
      end
    end

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
  end
end