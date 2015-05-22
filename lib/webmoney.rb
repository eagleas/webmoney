#encoding: utf-8
# :title:Webmoney library Documentation
# :main:lib/webmoney.rb
# :include:README

require 'time'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'nokogiri'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
%w(signer interfaces wmid passport purse request_xml request_retval request_result messenger).each{|lib| require lib}

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

    # When x509, key and cert is path to file or filename in ~/.wm/,
    # or initialized PKey::RSA and X509::Certificate objects
    def detect_file(option)
      pathes = %w(%s ~/.wm/%s)
      pathes.map{|path| File.expand_path(path % option)}.detect{|path| File.file?(path)}
    end

    if file = detect_file(opt[:key])
      # light
      @key = OpenSSL::PKey::RSA.new(File.read(file), opt[:password])
      @cert = OpenSSL::X509::Certificate.new(File.read(detect_file(opt[:cert])))
    elsif opt[:key].is_a? OpenSSL::PKey::RSA
      # initialized OpenSSL::PKey::RSA objects
      @key = opt[:key]
      @cert = opt[:cert]
    elsif opt[:password]
      # key is classic base64-encoded key
      @signer = Signer.new(@wmid, opt[:password], opt[:key])
    end

    # ca_cert or default
    @ca_cert =
      if opt[:ca_cert].nil?
         File.dirname(__FILE__) + '/../ssl-certs/ca_bundle.crt'
      else
        opt[:ca_cert]
      end

    @rid = opt[:rid]

    # encode will raise exception,
    # when uncovertable character in input sequence. It is default behavior.
    # With option :force_encoding uncovertable characters will be cutted.
    @force_encoding = opt[:force_encoding]

    # for backward compatibility with ruby 1.8
    if String.new.respond_to?(:encode)

      # was: @ic_out
      def utf8_to_cp1251(str)
        return str if str.nil? || str.length < 1
        @force_encoding ? str.encode('CP1251', 'UTF-8', :undef => :replace, :replace => '') : str.encode('CP1251', 'UTF-8')
      end

      # was: @ic_in
      def cp1251_to_utf8(str)
        return str if str.empty?
        str.encode('UTF-8', 'CP1251')
      end

    else
      require 'iconv'

      # was: @ic_out
      def utf8_to_cp1251(str)
        @force_encoding ? Iconv.iconv('CP1251//IGNORE', 'UTF-8', str)[0] : Iconv.iconv('CP1251', 'UTF-8', str)[0]
      end

      # was: @ic_in
      def cp1251_to_utf8(str)
        Iconv.iconv('UTF-8', 'CP1251', str)[0]
      end
    end

    def filter_str(str)
      if @force_encoding
        str_out = utf8_to_cp1251(str)
        [cp1251_to_utf8(str_out), str_out]
      else
        [str, utf8_to_cp1251(str)]
      end
    end

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

  # Make HTTPS request, return result body if 200 OK

  def https_request(iface, xml)
    @last_request = @last_response = nil

    url = @interfaces[iface]

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
    http.ssl_version = :TLSv1
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
  # return 14 digits string
  def reqn
    t = Time.now
    msec = t.to_f.to_s.match(/\.(\d\d)/)[1] rescue '00'
    t.strftime('%y%m%d%H%M%S') + msec
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
    return true if libxml.nil?

    [libxml['compiled'], libxml['loaded']].each do |ver|
      major, minor = ver.match(/^(\d+)\.(\d+).*/).to_a[1,2].map{|i| i.to_i}
      return false if major < 2 or minor < 7
    end
  end

end
