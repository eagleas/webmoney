module Webmoney
  # Presets for interfaces
  def interface_urls
    {
      :create_invoice      => w3s_url + 'XMLInvoice.asp',       # x1
      :create_transaction  => w3s_url + 'XMLTrans.asp',         # x2
      :operation_history   => w3s_url + 'XMLOperations.asp',    # x3
      :outgoing_invoices   => w3s_url + 'XMLOutInvoices.asp',   # x4
      :finish_protect      => w3s_url + 'XMLFinishProtect.asp', # x5
      :send_message        => w3s_url + 'XMLSendMsg.asp',       # x6
      :check_sign          => w3s_url + 'XMLClassicAuth.asp',   # x7
      :find_wm             => w3s_url + 'XMLFindWMPurse.asp',   # x8
      :balance             => w3s_url + 'XMLPurses.asp',        # x9
      :incoming_invoices   => w3s_url + 'XMLInInvoices.asp',    # x10
      :get_passport        => 'https://passport.webmoney.ru/asp/XMLGetWMPassport.asp', # x11
      :reject_protection   => w3s_url + 'XMLRejectProtect.asp', # x13
      :transaction_moneyback => w3s_url + 'XMLTransMoneyback.asp', # x14
      :i_trust             => w3s_url + 'XMLTrustList.asp',     # x15
      :trust_me            => w3s_url + 'XMLTrustList2.asp',    # x15
      :trust_save          => w3s_url + 'XMLTrustSave2.asp',    # x15
      :create_purse        => w3s_url + 'XMLCreatePurse.asp',   # x16
      :create_contract => 'https://arbitrage.webmoney.ru/xml/X17_CreateContract.aspx', # x17
      :transaction_get => 'https://merchant.webmoney.ru/conf/xml/XMLTransGet.asp',     # x18
      :bussines_level  => 'https://stats.wmtransfer.com/levels/XMLWMIDLevel.aspx',
      :login           => 'https://login.wmtransfer.com/ws/authorize.xiface'           # login
    }
  end
end