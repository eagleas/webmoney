module Webmoney::RequestResult    # :nodoc:all

  def result_check_sign(doc)
    doc.at('//testsign/res').inner_html == 'yes' ? true : false
  end

  def result_get_passport(doc)
    root = doc.xpath('/response')

    # We use latest attestat
    attestat = root.xpath('certinfo/attestat/row')[0]

    tid = attestat['tid'].to_i
    recalled = attestat['recalled'].to_i
    locked = root.xpath('certinfo/userinfo/value/row')[0]['locked'].to_i
    {
      :full_access => root.xpath('fullaccess')[0].text == '1',
      :attestat => {
        :attestat => (recalled + locked > 0) ? Webmoney::Passport::ALIAS : tid,
        :created_at => Time.xmlschema(attestat['datecrt'])}.
        merge(attestat.attributes.inject({}){|memo, a| memo.merge!(a[0] => a[1].value) })
    }
  end

  def result_bussines_level(doc)
    doc.at('//level').inner_html.to_i
  end

  def result_send_message(doc)
    time = doc.at('//message/datecrt').inner_html
    m = time.match(/(\d{4})(\d{2})(\d{2}) (\d{2}):(\d{2}):(\d{2})/)
    time = Time.mktime(*m[1..6])
    { :id => doc.at('//message')['id'], :date => time }
  end

  def result_find_wm(doc)
    {
      :retval => doc.at('//retval').inner_html.to_i,
      :wmid   => (doc.at('//testwmpurse/wmid').inner_html rescue nil),
      :purse  => (doc.at('//testwmpurse/purse').inner_html rescue nil)
    }
  end

end