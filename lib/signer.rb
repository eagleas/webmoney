require "base64"
require "stringio"
require "openssl"
require "securerandom"

class Signer
  module Key

    def self.read(io, wmid, password = nil)
      if !password.nil?

        header = io.read 30
        data = io.read

        begin
          return try_read_encrypted wmid, password, header, data
        rescue
          return try_read_encrypted wmid, password[0...password.length / 2], header, data
        end
      end

      reserved1, sign_flag = io.read(4).unpack("vv")
      crc    = io.read(16)
      length, = io.read(4).unpack("V")

      data = io.read
      raise "unexpected data length" if length != data.length

      digest = OpenSSL::Digest::MD4.new
      digest.update [ reserved1, 0 ].pack("v*")
      digest.update [ 0, 0, 0, 0, length ].pack("V*")
      digest.update data

      calculated_crc = digest.digest

      raise "invalid key digest" if crc != calculated_crc

      data_io = StringIO.new data[4..-1], 'rb'

      e = read_bn_from data_io
      n = read_bn_from data_io

      { :e => e, :n => n }
    end

    def self.try_read_encrypted(wmid, password, header, data)
        nested_io = StringIO.new ''.encode('BINARY'), 'rb+'
        nested_io.write header
        nested_io.write wm_encrypt(wmid, password, data)
        nested_io.rewind

        return self.read nested_io, wmid
    end

    def self.read_bn_from(io)
      bytes, = io.read(2).unpack("v")

      data = io.read(bytes).reverse

      OpenSSL::BN.new(data, 2)
    end

    def self.wm_encrypt(wmid, password, data)
      data = data.dup

      digest = OpenSSL::Digest::MD4.new
      digest.update wmid
      digest.update password

      key = digest.digest.unpack("C*")
      i = 0
      while i < data.length
        data[i] = (data[i].ord ^ key[i % key.length]).chr

        i += 1
      end

      data
    end
  end

  def initialize(wmid, password, key)
    raise ArgumentError, "nil wmid" if wmid.nil?
    raise ArgumentError, "Incorrect WMID" unless is_wmid wmid
    raise ArgumentError, "nil password" if password.nil?
    raise ArgumentError, "nil key" if key.nil?
    raise ArgumentError, "Illegal size for base64 keydata" unless key.length == 220

    key = Base64.decode64 key

    raise ArgumentError, "Illegal size for keydata" if key.length != 164

    io = StringIO.open key.force_encoding('BINARY'), 'rb'
    @key = Key.read io, wmid, password
  end

  def sign(data)
    raise ArgumentError, "nil data" if data.nil?

    digest = OpenSSL::Digest::MD4.new
    digest.update data
    data = digest.digest.unpack("V*")

    10.times do
      data << SecureRandom.random_number(1 << 32)
    end

    data = data.pack("V*")

    data = ([ data.length ].pack("v") + data).ljust( @key[:n].num_bytes, 0.chr).reverse

    data_bignum = OpenSSL::BN.new data, 2

    signature = data_bignum.mod_exp(@key[:e], @key[:n])

    signature.to_s(2).rjust(@key[:n].num_bytes, 0.chr).unpack('n*').reverse.map { |w| sprintf '%04x', w }.join
  end

  protected

  def is_wmid(string)
    if string =~ /^[0-9]{12}$/
      true
    else
      false
    end
  end
end
