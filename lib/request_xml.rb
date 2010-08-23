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
        x.sign( (classic? && opt[:mode]) ? sign(@wmid + opt[:wmid]) : nil )
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
    plan_out = @ic_out.iconv(opt[:plan])
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.testsign {
          x.wmid opt[:wmid]
          x.plan { x.cdata opt[:plan] }
          x.sign opt[:sign]
        }
        if classic?
          plan = @wmid + opt[:wmid] + plan_out + opt[:sign]
          x.sign sign(plan)
        end
      }
    }
  end

  def xml_send_message(opt)
    req = reqn()
    msgsubj = @ic_out.iconv(opt[:subj])
    msgtext = @ic_out.iconv(opt[:text])
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.wmid @wmid
        x.reqn req
        x.message do
          x.receiverwmid opt[:wmid]
          x.msgsubj { x.cdata opt[:subj] }
          x.msgtext { x.cdata opt[:text] }
        end
        if classic?
          @plan = opt[:wmid] + req + msgtext + msgsubj
          x.sign sign(@plan)
        end
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
        if classic?
          @plan = "#{opt[:wmid]}#{opt[:purse]}"
          x.sign sign(@plan)
        end
      }
    }
  end

    def xml_create_transaction(opt)
    req = reqn()
    desc = @ic_out.iconv(opt[:desc])                  # description
    Nokogiri::XML::Builder.new( :encoding => 'windows-1251' ) { |x|
      x.send('w3s.request') {
        x.reqn req
        x.wmid(@wmid) if classic?
          x.sign sign(@plan) if classic?
        x.trans {
          x.tranid opt[:transid]                      # transaction id - unique
          x.pursesrc opt[:pursesrc]                   # sender purse
          x.pursedest opt[:pursedest]                 # recipient purse
          x.amount opt[:amount]
          x.period( opt[:period] || 0 )                # protection period (0 - no protection)
          x.pcode( opt[:pcode].strip ) if opt[:period] > 0 && opt[:pcode]  # protection code
          x.desc desc
          x.wminvid( opt[:wminvid] || 0 )             # invoice number (0 - without invoice)
        }
      }
    }
  end

end
