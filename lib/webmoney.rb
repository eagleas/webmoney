#encoding: utf-8
# :title:Webmoney library Documentation
# :main:lib/webmoney.rb
# :include:README

require 'time'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'iconv'
require 'nokogiri'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
%w(wmsigner interfaces wmid passport purse request_xml request_retval request_result messenger).each{|lib| require lib}

# Module for Webmoney lib. Instance contain info
# for WMT-interfaces requests (wmid, key, etc).
# Implement general requests.
module Webmoney

  include RequestXML
  include RequestRetval
  include RequestResult

  # Error classes
  class WebmoneyError < StandardError; end
  class RequestError < WebmoneyError;  end
  class ResultError < WebmoneyError;  end
  class IncorrectWmidError < WebmoneyError; end
  class IncorrectPurseError < WebmoneyError; end
  class NonExistentWmidError < WebmoneyError; end
  class CaCertificateError < WebmoneyError; end
  
  attr_reader :wmid, :error, :errormsg, :last_request, :last_response, :interfaces, :rid
  attr_accessor :messenger


  # Preset for W3S
  def w3s_url
    'https://w3s.wmtransfer.com/asp/'
  end

  # Required options:
  #
  # - :wmid - WMID
  #
  # Optional:
  #
  # - :password - on Classic key or Light X509 certificate & key
  # - :key - Base64 string for Classic key
  # OR
  # - :key - OpenSSL::PKey::RSA or OpenSSL::PKey::DSA object
  # - :cert - OpenSSL::X509::Certificate object
  #
  # - :ca_cert - file CA certificate or path to directory with certs (in PEM format)

  def initialize(opt = {})

    unless check_libxml_version
      $stderr.puts "WARNING: webmoney lib will not work correctly with nokogori compiled with libxml2 version < 2.7.0"
    end

    @wmid = Wmid.new(opt[:wmid])

    # classic or light
    case opt[:key]
      when String
        @signer = Signer.new(@wmid, opt[:password], opt[:key])
      when OpenSSL::PKey::RSA, OpenSSL::PKey::DSA
        @key = opt[:key]
        @cert = opt[:cert]
        #@password = opt[:password]
    end

    # ca_cert or default
    @ca_cert =
      if opt[:ca_cert].nil?
         File.dirname(__FILE__) + '/../lib/certs/'
      else
        opt[:ca_cert]
      end

    @rid = opt[:rid]

    # Iconv.new(to, from)
    @ic_in = Iconv.new('UTF-8', 'CP1251')
    @ic_out = Iconv.new('CP1251', 'UTF-8')

    prepare_interface_urls

    # initialize workers by self
    Purse.worker = self
    Passport.worker = self
  end

  # Webmoney instance is classic type?
  def classic?
    !! @signer
  end
  
  # Send message through Queue and Thread
  #
  # Params: { :wmid, :subj, :text }

  def send_message(params)
    @messenger = Messenger.new(self){} if @messenger.nil?
    @messenger.push(params)
  end

  # Check existent WMID or not
  #
  # Params: wmid
  def wmid_exist?(wmid)
    request(:find_wm, :wmid => Wmid.new(wmid))[:retval] == 1
  end

  # Generic function for request to WMT-interfaces

  def request(iface, opt ={})
    raise ArgumentError, "should be hash" unless opt.kind_of?(Hash)

    # Use self wmid when not defined
    opt[:wmid] ||= @wmid

    # Do request
    res = https_request(iface, make_xml(iface, opt))

    # Parse response
    doc = Nokogiri::XML(res)
    parse_retval(iface, doc)
    make_result(iface, doc)
  end

  # Signing string by instance wmid's,
  # return signed string

  def sign(str)
    @signer.sign(str) unless str.nil? || str.empty?
  end

  protected

  def prepare_interface_urls
    @interfaces = interface_urls.inject({}) do |m,k|
      url = k[1]
      url.sub!(/(\.asp)/, 'Cert.asp') if !classic? && url.match("^"+w3s_url)
      m.merge!(k[0] => URI.parse(url))
    end
  end

  # Make HTTPS request, return result body if 200 OK

  def https_request(iface, xml)
    @last_request = @last_response = nil
    url = case iface
      when Symbol
        @interfaces[iface]
      when String
        URI.parse(iface)
    end
    raise ArgumentError, iface unless url
    http = Net::HTTP.new(url.host, url.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    if File.file? @ca_cert
      http.ca_file = @ca_cert
    elsif File.directory? @ca_cert
      http.ca_path = @ca_cert
    else
      raise CaCertificateError, @ca_cert
    end
    unless classic?
      http.cert = @cert
      http.key = @key
    end
    http.use_ssl = true
    @last_request = xml
    @last_response = result = http.post( url.path, xml, "Content-Type" => "text/xml" )
    case result
      when Net::HTTPSuccess
        result.body
      else
        @error = result.code
        @errormsg = result.body if result.class.body_permitted?()
        raise RequestError, [@error, @errormsg].join(' ')
    end
  end

  # Create unique Request Number based on time,
  # return 16 digits string
  def reqn
    t = Time.now
    msec = t.to_f.to_s.match(/\.(\d\d)/)[1] rescue '00'
    t.strftime('%Y%m%d%H%M%S') + msec
  end

  def make_xml(iface, opt)            # :nodoc:
    iface_func = "xml_#{iface}"
    send(iface_func, opt).to_xml
  end

  def parse_retval(iface, doc)         # :nodoc:
    method = "retval_#{iface}"
    if respond_to?(method)
      send(method, doc)
    else
      retval_common(doc)
    end
  end

  def make_result(iface, doc)         # :nodoc:
    iface_result = "result_#{iface}"
    send(iface_result, doc)
  end

  def check_libxml_version
    libxml = Nokogiri::VERSION_INFO['libxml']
    [libxml['compiled'], libxml['loaded']].each do |ver|
      major, minor = ver.match(/^(\d+)\.(\d+).*/).to_a[1,2].map{|i| i.to_i}
      return false if major < 2 or minor < 7
    end
  end

end
