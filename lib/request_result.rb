#encoding: utf-8
module Webmoney::RequestResult    # :nodoc:all

  def result_check_sign(doc)
    doc.at('//testsign/res').inner_html == 'yes' ? true : false
  end

  def result_get_passport(doc)
    Webmoney::Passport.parse_result(doc)
  end

  def result_bussines_level(doc)
    doc.at('//level').inner_html.to_i
  end

  def result_send_message(doc)
    {
      :id => doc.at('//message')['id'],
      :date => Time.parse(doc.at('//message/datecrt').inner_html)
    }
  end

  def result_find_wm(doc)
    {
      :retval => doc.at('//retval').inner_html.to_i,
      :wmid   => (doc.at('//testwmpurse/wmid').inner_html rescue nil),
      :purse  => (doc.at('//testwmpurse/purse').inner_html rescue nil)
    }
  end

  def result_create_invoice(doc)
    res = {
      :retval => doc.at('//retval').inner_html.to_i,
      :retdesc   => (doc.at('//testwmpurse/retdesc').inner_html rescue nil),
      :orderid  => doc.at('//invoice/orderid').inner_html.to_i
    }
    if res[:retval] == 0
      res[:id]  = doc.at('//invoice')['id'].to_i
      res[:ts]  = doc.at('//invoice')['ts'].to_i
      res[:state] = doc.at('//invoice/state').inner_html.to_i
      res[:created_at] = Time.parse(doc.at('//invoice/datecrt').inner_html)
    end
    res
  end

  def result_create_transaction(doc)
    op = doc.at('//operation')
    {
      :operation_id => op['id'],
      :operation_ts => op['ts']
    }.merge( op.children.inject({}) do |memo, elm|
      memo.merge!(elm.name.to_sym => elm.text)
    end )
  end

  def result_outgoing_invoices(doc)
    res = {
      :retval => doc.at('//retval').inner_html.to_i,
      :retdesc   => (doc.at('//testwmpurse/retdesc').inner_html rescue nil),
    }
    res[:invoices] = doc.xpath('//outinvoices/outinvoice').map do |invoice|
      r = {
        :id => invoice['id'].to_i,
        :ts => invoice['ts'].to_i,
      }
      invoice.elements.each do |tag|
        name = tag.name.to_sym
        value = tag.inner_html
        value = value.to_i if [:orderid, :tranid, :period, :expiration, :wmtranid, :state].include?(name)
        value = value.to_f if [:rest, :amount, :comiss].include?(name)
        value = Time.parse(value) if [:datecrt, :dateupd].include?(name)
        value = cp1251_to_utf8(value) if [:desc, :address].include?(name)
        r[name] = value
      end
      r
    end
    res
  end

  def result_login(doc)
    {
      :retval => doc.at('/response')['retval'].to_i,
      :retdesc   => doc.at('/response')['sval'],
      :lastAccess => doc.at('/response')['lastAccess'],
      :expires => doc.at('/response')['expires']
    }
  end

  def result_trust_me(doc)
    {
      :count        => doc.at('//trustlist')['cnt'].to_i,
      :invoices     => doc.xpath('//trust[@inv="1"]/purse').map(&:inner_text),
      :transactions => doc.xpath('//trust[@trans="1"]/purse').map(&:inner_text),
      :balance      => doc.xpath('//trust[@purse="1"]/purse').map(&:inner_text),
      :history      => doc.xpath('//trust[@transhist="1"]/purse').map(&:inner_text)
    }
  end

  def result_transaction_get(doc)
    if doc.at('//operation')
      wminvoiceid = doc.at('//operation')['wminvoiceid'].to_i
      wmtransid = doc.at('//operation')['wmtransid'].to_i
      enumflag = doc.at('//operation/enumflag').inner_html.to_i if doc.at('//operation/enumflag')
      amount = doc.at('//operation/amount').inner_html.to_f
      operdate = Time.parse(doc.at('//operation/operdate').inner_html)
      pursefrom = doc.at('//operation/pursefrom').inner_html
      wmidfrom = doc.at('//operation/wmidfrom').inner_html
      capitallerflag = doc.at('//operation/capitallerflag').inner_html.to_i
      ip = doc.at('//operation/IPAddress').inner_html
      phone = doc.at('//operation/telepat_phone').inner_html if doc.at('//operation/telepat_phone')
      telepat_paytype = doc.at('//operation/telepat_paytype').inner_html.to_i
      payment_number = doc.at('//operation/paymer_number').inner_html
      paymer_type = doc.at('//operation/paymer_type').inner_html.to_i
      {
          :retval => doc.at('//retval').inner_html,
          :retdesc => doc.at('//retdesc').inner_html,
          :wminvoiceid => wminvoiceid,
          :wmtransid => wmtransid,
          :amount => amount,
          :operdate => operdate,
          :pursefrom => pursefrom,
          :wmidfrom => wmidfrom,
          :capitallerflag => capitallerflag,
          :enumflag => enumflag.to_i,
          :IPAddress => ip,
          :telepat_phone => phone,
          :telepat_paytype => telepat_paytype,
          :paymer_number => payment_number,
          :paymer_type => paymer_type
      }
    else
      {
          :retval => doc.at('//retval').inner_html,
          :retdesc => doc.at('//retdesc').inner_html
      }
    end
  end

  def result_req_payment(doc)
    {
        :wminvoiceid  => doc.at('//operation')['wminvoiceid'].to_i,
        :realsmstype  => doc.at('//operation')['realsmstype'].to_i,
        :retval       => doc.at('//retval').inner_html.to_i,
        :retdesc      => doc.at('//retdesc').inner_html,
        :userdesc      => doc.at('//userdesc').inner_html
    }
  end

  def result_conf_payment(doc)
    if doc.at('//smssentstate').nil? || doc.at('//smssentstate').blank?
      smsstate = nil
    else
      smsstate = doc.at('//smssentstate').inner_html
    end
    {
        :wminvoiceid    => doc.at('//operation')['wminvoiceid'].to_i,
        :wmtransid      => doc.at('//operation')['wmtransid'].to_i,
        :amount         => doc.at('//operation/amount').inner_html.to_f,
        :operdate       => Time.parse(doc.at('//operation/operdate').inner_html),
        :pursefrom      => doc.at('//operation/pursefrom').inner_html,
        :wmidfrom       => doc.at('//operation/wmidfrom').inner_html,
        :retval         => doc.at('//retval').inner_html.to_i,
        :retdesc        => doc.at('//retdesc').inner_html,
        :smssentstate   => smsstate
    }
  end

  alias_method :result_i_trust, :result_trust_me

  def result_check_user(doc)
    {
      :retval => doc.at('//retval').inner_html.to_i
    }
  end

  def result_balance(doc)
    purses = []
    doc.at('//purses').children.each do |purse|
      purses_hash = {}
      purse.children.each do |child|
        purses_hash[child.name.to_sym] = child.content
      end
      purses << purses_hash unless purses_hash.empty?
    end
    {
      :purses => purses,
      :retval => doc.at('//retval').inner_html.to_i
    }
  end

  def result_operation_history(doc)
    operations = []
    doc.at('//operations').children.each do |operation|
        operations_hash = {}
        operation.attribute("ts")
        operation.children.each do |child|
            operations_hash[child.name.to_sym] = child.content
            "ts".to_sym = operation.attribute("ts")
            "id".to_sym = operation.attribute("id")
        end
        operations << operations_hash unless operations_hash.empty?
    end
    {
        :operations => operations,
        :retval => doc.at('//retval').inner_html.to_i
    }
  end
end
