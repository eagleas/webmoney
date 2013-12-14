module Webmoney

  # Presets for interfaces
  def interface_urls
    {
      :create_invoice     => { :url => 'XMLInvoice.asp' },       # x1
      :create_transaction => { :url => 'XMLTrans.asp' },         # x2
      :operation_history  => { :url => 'XMLOperations.asp' },    # x3
      :outgoing_invoices  => { :url => 'XMLOutInvoices.asp' },   # x4
      :finish_protect     => { :url => 'XMLFinishProtect.asp' }, # x5
      :send_message       => { :url => 'XMLSendMsg.asp' },       # x6
      :check_sign         => { :url => 'XMLClassicAuth.asp' },   # x7
      :find_wm            => { :url => 'XMLFindWMPurse.asp' },   # x8
      :balance            => { :url => 'XMLPurses.asp' },        # x9
      :incoming_invoices  => { :url => 'XMLInInvoices.asp' },    # x10
      :get_passport       => { :url => 'https://passport.webmoney.ru/asp/XMLGetWMPassport.asp' , # x11
                               :x509 => lambda {|url| url.sub(/\.asp$/, 'Cert.asp')} },
      :reject_protection  => { :url => 'XMLRejectProtect.asp' }, # x13
      :transaction_moneyback => { :url => 'XMLTransMoneyback.asp' }, # x14
      :i_trust            => { :url => 'XMLTrustList.asp'  },    # x15
      :trust_me           => { :url => 'XMLTrustList2.asp' },    # x15
      :trust_save         => { :url => 'XMLTrustSave2.asp' },    # x15
      :create_purse       => { :url => 'XMLCreatePurse.asp' },   # x16
      :create_contract    => { :url => 'https://arbitrage.webmoney.ru/xml/X17_CreateContract.aspx', },  # x17
      :get_contract_info  => { :url => 'https://arbitrage.webmoney.ru/xml/X17_GetContractInfo.aspx' }, # x17
      :transaction_get    => { :url => 'https://merchant.webmoney.ru/conf/xml/XMLTransGet.asp' },      # x18
      :check_user         => { :url => 'https://apipassport.webmoney.ru/XMLCheckUser.aspx',            # x19
                               :x509 => lambda {|url| 'https://apipassportcrt.webmoney.ru/XMLCheckUserCert.aspx' } },
      :bussines_level     => { :url => 'https://stats.wmtransfer.com/levels/XMLWMIDLevel.aspx' },
      :login              => { :url => 'https://login.wmtransfer.com/ws/authorize.xiface' },           # login
    }
  end

  protected

  def prepare_interface_urls

    # default transform to x509 version for w3s urls
    default_lambda = lambda {|url| url.sub(/\.asp$/, 'Cert.asp') }

    @interfaces = interface_urls.inject({}) do |m,(k,v)|
      url = v[:url]
      unless url.match %r{^https://}
        url = w3s_url + url
        url = default_lambda.call(url) if !classic?
      else
        transform = v[:x509]
        url = transform.call(url) if !classic? && transform && transform.respond_to?(:call)
      end
      m.merge!(k => URI.parse(url))
    end

  end

end
