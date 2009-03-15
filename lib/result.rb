module Webmoney::RequestResult    # :nodoc:all

  def result_check_sign(doc)
    doc.at('//testsign/res').inner_html == 'yes' ? true : false
  end

  def result_get_passport(doc)
    Webmoney::Passport.new(doc)
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
end