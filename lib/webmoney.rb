=begin rdoc
== About Webmoney library

This library help to make requests to WebMoney Transfer http://www.wmtransfer.com
XML-interfaces: http://www.wmtransfer.com/eng/developers/interfaces/index.shtml

Gem have built-in native *wmsigner*.

Author::    Alexander Oryol (mailto:eagle.alex@gmail.com)
License::   MIT License

== Request types

- create_invoice     - x1
- create_transaction - x2
- operation_history  - x3
- outgoing_invoices  - x4
- finish_protect     - x5
- send_message       - x6
- check_sign         - x7
- find_wm            - x8
- balance            - x9
- incoming_invoices  - x10
- get_passport       - x11
- reject_protection  - x13
- transaction_moneyback - x14
- i_trust               - x15
- trust_me              - x15
- trust_save            - x15
- create_purse          - x16
- bussines_level

Please, see relative documentation and parameters on wiki:

http://wiki.wmtransfer.com/wiki/list/XML-Interfaces

http://wiki.webmoney.ru/wiki/list/XML-%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D1%84%D0%B5%D0%B9%D1%81%D1%8B (in russian)

or official sites:

http://www.wmtransfer.com/eng/developers/interfaces/xml/index.shtml

http://www.webmoney.ru/rus/developers/interfaces/xml/index.shtml (in russian)

== Examples

@wm = Webmoney.new(:wmid => '123456789012', :password => 'my_pass', :key => 'gQABAIR6...2cC8FZTyKyjBM=')

passport = @wm.request(:get_passport, :wmid => @wm.wmid)

bl = @wm.request(:bussines_level, :wmid => '123456789012')

@wm.request(:send_message, :wmid => @wm.wmid, :subj => 'Subject', :text => 'Body of \<b>message\</b>')


Also, see examples into spec's.
=end


# :title:Webmoney library Documentation
# :main:lib/webmoney.rb
# :include:README

require 'time'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'iconv'
require 'builder'
require 'hpricot'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'wmsigner'
require 'wmid'
require 'passport'
require 'request'
require 'result'
require 'messenger'

# Main class for Webmoney lib. Instance contain info
# for WMT-interfaces requests (wmid, key, etc).
# Implement general requests.
class Webmoney

  include XMLRequest
  include RequestResult

  # Error classes
  class WebmoneyError < StandardError; end
  class RequestError < WebmoneyError;  end
  class ResultError < WebmoneyError;  end
  class IncorrectWmidError < WebmoneyError; end
  class CaCertificateError < WebmoneyError; end
  
  attr_reader :wmid, :error, :errormsg, :last_request, :messenger
  
  # Required options:
  #
  # - :wmid - WMID
  # - :password - on Classic key or Light X509 certificate & key
  # - :key - Base64 string for Classic key
  #
  # OR
  # #TODO
  # - :key - OpenSSL::PKey::RSA or OpenSSL::PKey::DSA object
  # - :cert - OpenSSL::X509::Certificate object
  #
  # Optional:
  #
  # - :ca_cert - path of a CA certification file in PEM format

  def initialize(opt = {})
    @wmid = Wmid.new(opt[:wmid])
    
    # classic or light
    case opt[:key]
      when String
        @signer = Signer.new(@wmid, opt[:password], opt[:key])
      when OpenSSL::PKey::RSA, OpenSSL::PKey::DSA
        @key = opt[:key]
        @cert = opt[:cert]
        @password = opt[:password]
    end
    
    # ca_cert or default
    @ca_cert = 
      if opt[:ca_cert].nil?
         File.dirname(__FILE__) + '/../lib/WebMoneyCA.crt'
      else
        opt[:ca_cert]
      end

    w3s = 'https://w3s.wmtransfer.com/asp/'
    
    @interfaces = {
      'create_invoice'  => URI.parse( w3s + 'XMLInvoice.asp' ), # x1
      'create_transaction'  => URI.parse( w3s + 'XMLTrans.asp' ), # x2
      'operation_history'  => URI.parse( w3s + 'XMLOperations.asp' ), # x3
      'outgoing_invoices'  => URI.parse( w3s + 'XMLOutInvoices.asp' ), # x4
      'finish_protect'  => URI.parse( w3s + 'XMLFinishProtect.asp' ), # x5
      'send_message'  => URI.parse( w3s + 'XMLSendMsg.asp'), # x6
      'check_sign'  => URI.parse( w3s + 'XMLClassicAuth.asp'), # x7
      'find_wm'  => URI.parse( w3s + 'XMLFindWMPurse.asp'), # x8
      'balance'  => URI.parse( w3s + 'XMLPurses.asp'), # x9
      'incoming_invoices' => URI.parse( w3s + 'XMLInInvoices.asp'), # x10
      'get_passport' => URI.parse( 'https://passport.webmoney.ru/asp/XMLGetWMPassport.asp'), # x11
      'reject_protection' => URI.parse( w3s + 'XMLRejectProtect.asp'), # x13
      'transaction_moneyback' => URI.parse( w3s + 'XMLTransMoneyback.asp'), # x14
      'i_trust'  => URI.parse( w3s + 'XMLTrustList.asp'), # x15
      'trust_me'  => URI.parse( w3s + 'XMLTrustList2.asp'), # x15
      'trust_save'  => URI.parse( w3s + 'XMLTrustSave2.asp'), # x15
      'create_purse'  => URI.parse( w3s + 'XMLCreatePurse.asp'), # x16
      'bussines_level'  => URI.parse( 'https://stats.wmtransfer.com/levels/XMLWMIDLevel.aspx')
    }
    # Iconv.new(to, from)
    @ic_in = Iconv.new('UTF-8', 'CP1251')
    @ic_out = Iconv.new('CP1251', 'UTF-8')
  end

  # Webmoney instance is classic type?

  def classic?
    ! @signer.nil?
  end
  
  # Send message through Queue and Thread
  #
  # Params: { :wmid, :subj, :text }

  def send_message(params)
    @messenger = Messenger.new(self) if @messenger.nil?
    @messenger.push(params)
  end
  
  # Generic function for request to WMT-interfaces

  def request(iface, opt ={})
    reqn = reqn()
    raise ArgumentError unless opt.kind_of?(Hash)
    opt[:wmid] = @wmid if opt[:wmid].nil?

    # Do request
    res = https_request(iface, make_xml(iface, opt))

    # Parse response
    parse_retval(res)
    make_result(iface, res)
  end

  # Signing string by instance wmid's,
  # return signed string

  def sign(str)
    @signer.sign(str) unless str.nil? || str.empty?
  end

  protected

  # Make HTTPS request, return result body if 200 OK

  def https_request(iface, xml)
    url = case iface
      when Symbol
        @interfaces[iface.to_s]
      when String
        URI.parse(iface)
    end
    http = Net::HTTP.new(url.host, url.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    if File.file? @ca_cert
      http.ca_file = @ca_cert
    else
      raise CaCertificateError, @ca_cert
    end
    http.use_ssl = true
    @last_request = xml
    result = http.post( url.path, xml, "Content-Type" => "text/xml" )
    case result
      when Net::HTTPSuccess
        # replace root tag for Hpricot
        res = result.body.gsub(/(w3s\.response|WMIDLevel\.response)/,'w3s_response')
        return @ic_in.iconv(res)
      else
        @error = result.code
        @errormsg = result.body if result.class.body_permitted?()
        raise RequestError, [@error, @errormsg].join(' ')
    end
  end

  def parse_retval(response_xml)         # :nodoc:
    doc = Hpricot.XML(response_xml)
    retval_element = doc.at('//retval')
    # Workaround for passport interface
    unless retval_element.nil?
      retval = retval_element.inner_html.to_i
      retdesc = doc.at('//retdesc').inner_html unless doc.at('//retdesc').nil?
    else
      retval = doc.at('//response')['retval'].to_i
      retdesc = doc.at('//response')['retdesc']
    end
    unless retval == 0
        @error = retval
        @errormsg = retdesc
        raise ResultError, [@error, @errormsg].join(' ')
    end
  end

  # Create unique Request Number based on time,
  # return 16 digits string
  def reqn
    t = Time.now
    t.strftime('%Y%m%d%H%M%S') + t.to_f.to_s.match(/\.(\d\d)/)[1]
  end

  def make_xml(iface, opt)
    iface_func = ('xml_'+iface.to_s).to_sym
    self.send(iface_func, opt).target!
  rescue NoMethodError
    raise NotImplementedError, "#{iface_func}()"
  end

  def make_result(iface, res)
    doc = Hpricot.XML(res)
    iface_result = ('result_'+iface.to_s).to_sym
    self.send(iface_result, doc)
  rescue NoMethodError
    raise NotImplementedError, "#{iface_result}()"
  end

end
