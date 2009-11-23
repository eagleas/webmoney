# Class for store attestat information
module Webmoney

  class Passport < Wmid

    class Attribute < String
      attr_accessor :checked, :locked
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

    def self.parse_result(doc)
      root = doc.xpath('/response')

      # We use latest attestat
      attestat = root.xpath('certinfo/attestat/row')[0]

      tid = attestat['tid'].to_i
      recalled = attestat['recalled'].to_i
      locked = root.xpath('certinfo/userinfo/value/row')[0]['locked'].to_i

      userinfo = root.xpath('certinfo/userinfo/value/row')[0].attributes.inject({}) { |memo, a|
          a[1].value.empty? ? memo : memo.merge!(a[0].to_sym => Attribute.new(a[1].value))
      }
      root.xpath('certinfo/userinfo/check-lock/row')[0].attributes.each_pair do |k,v|
        attr = userinfo[k.to_sym]
        unless attr.nil?
          attr.checked = v[0] == '1'
          attr.locked  = v[1] == '1'
        end
      end

      wmids = root.xpath('certinfo/wmids/row').inject({}) do |memo, elm|
        attrs = {:created_at => Time.xmlschema(elm['datereg'])}
        attrs.merge!(:nickname => elm['nickname']) unless elm['nickname'].empty?
        attrs.merge!(:info => elm['info']) unless elm['info'].empty?
        memo.merge!(elm['wmid'] => attrs)
      end

      {
        :full_access => root.xpath('fullaccess')[0].text == '1',
        :attestat => {
          :attestat => (recalled + locked > 0) ? ALIAS : tid,
          :created_at => Time.xmlschema(attestat['datecrt'])}.
          merge(attestat.attributes.inject({}){|memo, a| a[1].value.empty? ? memo : memo.merge!(a[0].to_sym => a[1].value) }),
        :userinfo => userinfo,
        :wmids => wmids
      }
    end

  end
end