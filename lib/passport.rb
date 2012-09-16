#encoding: utf-8
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

    # extra permit :dict, :info, :dict params
    def initialize(str, extra = {})
      super(str)
      @extra = extra
    end

    # memoize data
    def attestat; @attestat ||= getinfo[:attestat] end
    def directory; @directory ||= getinfo[:directory] end
    def full_access; @full_access = getinfo[:full_access] end
    def userinfo; @userinfo ||= getinfo[:userinfo] end
    def wmids; @userinfo ||= getinfo[:wmids] end

    protected

    def getinfo
      @info ||= @@worker.request(:get_passport, @extra.merge(:wmid => self))
    end

    def self.parse_result(doc)
      root = doc.at('/response')

      # We use latest attestat
      att_elm = root.at('certinfo/attestat/row')

      tid = att_elm['tid'].to_i
      recalled = att_elm['recalled'].to_i
      locked = root.at('certinfo/userinfo/value/row')['locked'].to_i

      attestat = {
        :attestat => (recalled + locked > 0) ? ALIAS : tid,
        :created_at => Time.xmlschema(att_elm['datecrt'])
      }
      attestat.merge!( att_elm.attributes.inject({}) do |memo, a|
        a[1].value.empty? ? memo : memo.merge!(a[0].to_sym => a[1].value)
      end )

      userinfo = root.at('certinfo/userinfo/value/row').attributes.inject({}) { |memo, a|
        memo.merge!(a[0].to_sym => Attribute.new(a[1].value.strip))
      }
      root.at('certinfo/userinfo/check-lock/row').attributes.each_pair do |k,v|
        attr = userinfo[k.to_sym]
        attr.checked = v.to_s[0,1] == '1'
        attr.locked  = v.to_s[1,2] == '1'
      end

      wmids = root.xpath('certinfo/wmids/row').inject({}) do |memo, elm|
        attrs = {:created_at => (Time.xmlschema(elm['datereg']) rescue nil)}
        attrs.merge!(:nickname => elm['nickname']) unless elm['nickname'].empty?
        attrs.merge!(:info => elm['info']) unless elm['info'].empty?
        memo.merge!(elm['wmid'] => attrs)
      end

      if dir = root.at('directory')
        directory = {
          :ctype => dir.xpath('ctype').inject({}){|memo, node| memo.merge!(node['id'].to_i => node.text)},
          :jstatus => dir.xpath('jstatus').inject({}){|memo, node| memo.merge!(node['id'].to_i => node.text)},
          :types => dir.xpath('tid').inject({}){|memo, node| memo.merge!(node['id'].to_i => node.text)}
        }
      end

      result = {
        :full_access => root.at('fullaccess').text == '1',
        :attestat => attestat,
        :wmids => wmids,
        :userinfo => userinfo
      }
      result.merge!(:directory => directory) if dir
      result
    end

  end
end
