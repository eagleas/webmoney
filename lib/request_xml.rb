#encoding: utf-8
module Webmoney::RequestXML    # :nodoc:all

  def xml_get_passport(opt)
    Nokogiri::XML::Builder.new { |x|
      x.request {
        x.wmid @wmid
        x.passportwmid opt[:wmid]
        x.params {
          x.dict opt[:dict] || 0
          x.info opt[:info] || 1
          x.mode opt[:mode] || 0
        }
        # unless mode == 1, signed data need'nt
        x.sign( (classic? && opt[:mode]) ? sign("#{@wmid}#{opt[:wmid]}") : nil )
      }
    }
  end

  def xml_bussines_level(opt)
    Nokogiri::XML::Builder.new { |x|
      x.send('WMIDLevel.request') {
        x.signerwmid @wmid
        x.wmid opt[:wmid]
      }
    }
  end

  def xml_check_sign(opt)
    plan_in, plan_out = filter_str(opt[:plan])
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.testsign {
          x.wmid opt[:wmid]
          x.plan { x.cdata plan_in }
          x.sign opt[:sign]
        }
        x.sign sign("#{@wmid}#{opt[:wmid]}#{plan_out}#{opt[:sign]}") if classic?
      }
    }
  end

  def xml_send_message(opt)
    req = reqn()
    subj_in, subj_out = filter_str(opt[:subj])
    text_in, text_out = filter_str(opt[:text])
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.reqn req
        x.message do
          x.receiverwmid opt[:wmid]
          x.msgsubj { x.cdata subj_in }
          x.msgtext { x.cdata text_in }
        end
        x.sign sign("#{opt[:wmid]}#{req}#{text_out}#{subj_out}") if classic?
      }
    }
  end

  def xml_find_wm(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.reqn req
        x.testwmpurse do
          x.wmid( opt[:wmid] || '' )
          x.purse( opt[:purse] || '' )
        end
        x.sign sign("#{opt[:wmid]}#{opt[:purse]}") if classic?
      }
    }
  end

  def xml_create_invoice(opt)
    req = reqn()
    desc_in, desc_out = filter_str(opt[:desc])
    address_in, address_out = filter_str(opt[:address])
    amount = opt[:amount].to_f.to_s.gsub(/\.?0+$/, '')
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{opt[:orderid]}#{opt[:customerwmid]}#{opt[:storepurse]}#{amount}#{desc_out}#{address_out}#{opt[:period]||0}#{opt[:expiration]||0}#{req}") if classic?
        x.invoice do
          x.orderid opt[:orderid]
          x.customerwmid opt[:customerwmid]
          x.storepurse opt[:storepurse]
          x.amount amount
          x.desc desc_in
          x.address address_in
          x.period opt[:period].to_i
          x.expiration opt[:expiration].to_i
        end
      }
    }
  end

  def xml_create_transaction(opt)
    req = reqn()
    desc_in, desc_out = filter_str(opt[:desc])                  # description
    pcode = opt[:pcode].strip if opt[:period] > 0 && opt[:pcode]
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid(@wmid)
        x.sign sign("#{req}#{opt[:transid]}#{opt[:pursesrc]}#{opt[:pursedest]}#{opt[:amount]}#{opt[:period]||0}#{pcode}#{desc_out}#{opt[:wminvid]||0}") if classic?
        x.trans {
          x.tranid opt[:transid]                      # transaction id - unique
          x.pursesrc opt[:pursesrc]                   # sender purse
          x.pursedest opt[:pursedest]                 # recipient purse
          x.amount opt[:amount]
          x.period( opt[:period] || 0 )                # protection period (0 - no protection)
          x.pcode( pcode ) if pcode  # protection code
          x.desc desc_in
          x.wminvid( wminvid )             # invoice number (0 - without invoice)
        }
      }
    }
  end

  def xml_outgoing_invoices(opt)
    req = reqn()
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{opt[:purse]}#{req}") if classic?
        x.getoutinvoices do
          x.purse opt[:purse]
          x.wminvid opt[:wminvid]
          x.orderid opt[:orderid]
          x.datestart opt[:datestart].strftime("%Y%m%d %H:%M:%S")
          x.datefinish opt[:datefinish].strftime("%Y%m%d %H:%M:%S")
        end
      }
    }
  end

  def xml_login(opt)
    Nokogiri::XML::Builder.new { |x|
      x.send('request') {
        x.siteHolder opt[:siteHolder] || @wmid
        x.user opt[:WmLogin_WMID]
        x.ticket opt[:WmLogin_Ticket]
        x.urlId  opt[:WmLogin_UrlID]
        x.authType opt[:WmLogin_AuthType]
        x.userAddress opt[:remote_ip]
      }
    }
  end

  def xml_i_trust(opt)
    opt[:wmid] = @wmid
    xml_trust_me(opt)
  end

  def xml_trust_me(opt)
    req = reqn()
    Nokogiri::XML::Builder.new { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid @wmid
        x.sign sign("#{opt[:wmid]}#{req}")
        x.gettrustlist do
          x.wmid opt[:wmid]
        end
      }
    }
  end

end
