#encoding: utf-8
module Webmoney::RequestRetval    # :nodoc:all

  def retval_common(doc)
    retval_element = doc.at('//retval')
    @error = retval_element.inner_html.to_i
    @errormsg = doc.at('//retdesc') ? doc.at('//retdesc').inner_html : ''
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @error == 0
  end

  def retval_get_passport(doc)
    # retval is attribute <response>
    @error = doc.at('//response')['retval'].to_i
    @errormsg = doc.at('//response')['retdesc']
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @error == 0
    raise Webmoney::NonExistentWmidError unless doc.at('/response/certinfo/attestat')
  end

  def retval_find_wm(doc)
    # do nothing
    # retval = { 1 - found; 0 - not found }
  end

  def retval_create_invoice(doc)
    @error = doc.at('//retval').inner_html.to_i
    @errormsg = doc.at('//retdesc').inner_html
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @error == 0
  end

  def retval_outgoing_invoices(doc)
    @error = doc.at('//retval').inner_html.to_i
    @errormsg = doc.at('//retdesc').inner_html
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @error == 0
  end

  def retval_login(doc)
    @error = doc.at('/response')['retval'].to_i
    @errormsg = doc.at('/response')['sval']
    raise Webmoney::RequestError, [@error, @errormsg].join(' ') if @error == -1 || @error == 1
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @error == 0
  end

end
