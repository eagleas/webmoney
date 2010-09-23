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
      :orderid  => (doc.at('//invoice/orderid').inner_html.to_i),
    }
    if res[:retval] == 0
      res[:id]  = (doc.at('//invoice').attributes['id'].value.to_i)
      res[:ts]  = (doc.at('//invoice').attributes['ts'].value.to_i)
      res[:state] = (doc.at('//invoice/state').inner_html.to_i)
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
    if res[:retval] == 0
      res[:invoices] = doc.at('//outinvoices').elements.collect do |invoice|
        r = {
          :id => invoice.attributes['id'].value.to_i,
          :ts => invoice.attributes['ts'].value.to_i,
        }
        invoice.elements.each do |tag|
          name = tag.name.to_sym
          value = tag.inner_html
          value = value.to_i if [:orderid, :tranid, :period, :expiration, :wmtranid, :state].include?(name)
          value = value.to_f if [:rest, :amount, :comiss].include?(name)
          value = Time.parse(value) if [:datecrt, :dateupd].include?(name)
          r[name] = value
        end
        r
      end
    end
    res
  end

  def result_login(doc)
    {
      :retval => doc.at('/response')['retval'].to_i,
      :retdesc   => doc.at('/response')['sval'],
      :lastAccess => doc.at('/response')['lastAccess'],
      :expires => Time.utc.parse(doc.at('/response')['expires'])
    }
  end

end
