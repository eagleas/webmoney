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
    if retval = doc.at('/response')['retval']
      @error = retval.to_i
      @errormsg = doc.at('/response')['sval']
    else
      @error = -3
      @errormsg = 'Unknown response'
    end
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @error == 0
  end

  def retval_transaction_get(doc)
    # do nothing
    retval_element = doc.at('//retval')
    @error = retval_element.inner_html.to_i
    @errormsg = doc.at('//retdesc').inner_html
    @gooderrors = [0, 8, 9, 10, 11, 12]
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @gooderrors.include?(@error)
  end

  def retval_check_user(doc)
    retval_element = doc.at('//retval')
    @error = retval_element.inner_html.to_i
    @errormsg = doc.at('//retdesc') ? doc.at('//retdesc').inner_html : ''
    not_exception_result_errors = [0, 404]
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless not_exception_result_errors.include?(@error)
  end

  def retval_balance(doc)
    retval_element = doc.at('//retval')
    @error = retval_element.inner_html.to_i
    @errormsg = doc.at('//retdesc') ? doc.at('//retdesc').inner_html : ''
    raise Webmoney::ResultError, [@error, @errormsg].join(' ') unless @error == 0
  end

  def retval_req_payment(doc)
    retval_element = doc.at('//retval')
    @error = retval_element.inner_html.to_i
    @techerrordesc = doc.at('//retdesc').inner_html
    @errormsg = doc.at('//userdesc').inner_html
    raise Webmoney::ResultError, [@error, @errormsg].join('-') unless @error == 0 
  end

  def retval_conf_payment(doc)
    retval_element = doc.at('//retval')
    @error = retval_element.inner_html.to_i
    @errormsg = doc.at('//userdesc').inner_html
    @techerrordesc = doc.at('//retdesc').inner_html
    raise Webmoney::ResultError, [@error, @errormsg].join('-') unless @error == 0 
  end
end
