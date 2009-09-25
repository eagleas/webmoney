module Webmoney::RequestXML    # :nodoc:all

  def envelope(utf = true)
    x = Builder::XmlMarkup.new(:indent => 1)
    encoding = utf ? "utf-8" : "windows-1251"
    x.instruct!(:xml, :version => "1.0", :encoding => encoding)
    x
  end

  def xml_get_passport(opt)
    x = envelope(false)
    x.request do
      x.wmid @wmid
      x.passportwmid opt[:wmid]
      x.params { x.dict 0; x.info 1; x.mode 0 }
      x.sign sign(@wmid + opt[:wmid]) if classic?
    end
    x
  end

  def xml_bussines_level(opt)
    x = envelope
    x.tag!('WMIDLevel.request') do
      x.signerwmid @wmid
      x.wmid opt[:wmid]
    end
    x
  end

  def xml_check_sign(opt)
    x = envelope(false)
    x.tag!('w3s.request') do
      x.wmid @wmid
      plan_out = @ic_out.iconv(opt[:plan])
      x.testsign do
        x.wmid opt[:wmid]
        x.plan { x.cdata! plan_out }
        x.sign opt[:sign]
      end
      if classic?
        plan = @wmid + opt[:wmid] + plan_out + opt[:sign]
        x.sign sign(plan)
      end
    end
    x
  end

  def xml_send_message(opt)
    x = envelope(false)
    req = reqn()
    x.tag!('w3s.request') do
      x.wmid @wmid
      x.reqn req
      msgsubj = @ic_out.iconv(opt[:subj])
      msgtext = @ic_out.iconv(opt[:text])
      x.message do
        x.receiverwmid opt[:wmid]
        x.msgsubj { x.cdata! msgsubj }
        x.msgtext { x.cdata! msgtext }
      end
      if classic?
        @plan = opt[:wmid] + req + msgtext + msgsubj
        x.sign sign(@plan)
      end
    end
    x
  end

  def xml_find_wm(opt)
    x = envelope(false)
    req = reqn()
    x.tag!('w3s.request') do
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
    end
    x
  end

end
