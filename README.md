# About Webmoney library

This library should help to make requests to WebMoney Transfer http://www.wmtransfer.com
XML-interfaces: http://www.wmtransfer.com/eng/developers/interfaces/index.shtml

Gem have built-in native *wmsigner*.

Compatible with ruby: 1.8.7, 1.9.2
Reqirements: Nokogiri >= 1.4.1 built with libxml2 >= 2.7 (IMPORTANT!)

Author::    Alexander Oryol (mailto:eagle.alex@gmail.com)
License::   MIT License

# Request types

Completed:

* create_invoice     - x1
* create_transaction - x2
* outgoing_invoices  - x4
* send_message       - x6
* find_wm            - x8
* balance            - x9
* get_passport       - x11
* i_trust            - x15
* trust_me           - x15
* check_user         - x19
* bussines_level
* login

Incompleted (help need!):

* operation_history  - x3
* finish_protect     - x5
* check_sign         - x7
* incoming_invoices  - x10
* reject_protection  - x13
* transaction_moneyback - x14
* trust_save            - x15
* create_purse          - x16
* create_contract       - x17
* transaction_get       - x18


Please, see relative documentation and parameters on wiki:

http://wiki.wmtransfer.com/wiki/list/XML-Interfaces

http://wiki.webmoney.ru/wiki/list/XML-%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D1%84%D0%B5%D0%B9%D1%81%D1%8B (in russian)

or official sites:

http://www.wmtransfer.com/eng/developers/interfaces/xml/index.shtml

http://www.webmoney.ru/rus/developers/interfaces/xml/index.shtml (in russian)

# Examples

## Setup

```ruby
class MyWM
  include Webmoney
end
```

```ruby
@wm = MyWM.new(:wmid => '123456789012', :password => 'my_pass', :key => 'gQABAIR6...2cC8FZTyKyjBM=')

wmid = '111222333444'
```

## Light

The key convert instruction from P12 format to PEM see [here](http://wiki.webmoney.ru/projects/webmoney/wiki/konvertatsiya_klyuchey_wm_keeper_light_v_pem_format)

```ruby
mywm = MyWM.new(:wmid => '123456789012',
  :cert => 'webmoney.pem', # ~/.wm/webmoney.pem
#  :cert => '/home/user/webmoney.pem',
  :key =>  'webmoney.key', # ~/.wm/webmoney.key
#  :key =>  '/home/user/webmoney.key',
  :password => 'pa$$w0rt')
```
or

```ruby
cert = OpenSSL::X509::Certificate.new(File.read("webmoney.pem"))
key = OpenSSL::PKey::RSA.new(File.read("webmoney.key"), "password")
mywm = MyWM.new(:wmid => '123456789012', :cert => cert, :key => key)
```

## Passport (X11)

Get attestat data:

```ruby
passport = Webmoney::Passport.new(wmid, :mode => 1) # optionally :mode, :dict, :info
passport.attestat     # { # hash
                      #   :attestat => 110, # == FORMAL attestat, as example
                      #   :created_at => Wed Feb 25 21:54:01 +0300 2004 # Time object
                      #   :cid => "103453"
                      #   and etc.
                      # }
passport.wmids        # All wmids attached to the attestat
passport.userinfo[:country]          # => 'Russia' # Userinfo fields in string context
passport.userinfo[:country].checked  # => true     # with checked/locked attribute
passport.directory    # Base dictionary
```

## Bussines level

```ruby
bl = @wm.request(:bussines_level, :wmid => wmid)       #  => 15
```

## Sending message

... for one message:

```ruby
@wm.request(:send_message, :wmid => wmid, :subj => 'Subject', :text => 'Body of \<b>message\</b>')
```

... for many messages (with queue):

```ruby
@wm.send_message(:wmid => wmid, :subj => 'Subject', :text => 'Body of \<b>message\</b>') do |msg, result|
  File.open("logfile", "w") do |file|
    case result
    when Hash
      file.puts "Message #{msg.inspect} sended in:#{result[:date]} with id:#{result[:id]}"
    else
      file.puts "Error sent message #{msg.inspect}: #{result.message}"
    end
  end
end
```

## Purses and WMIDs

```ruby
@wm.wmid_exist?('123456789012')                   # => true

purse = Purse.new('Z123456789012')
purse.wmid                                        # => '123456789012'
purse.belong_to?('123456789012')                  # => true
```

## Example: Create invoice and check it's state

```ruby
@wm = MyWM.new(:wmid => '123456789012', :password => 'my_pass', :key => 'gQABAIR6...2cC8FZTyKyjBM=')
```

### Create invoice

```ruby
@invoice = @wm.request(:create_invoice,
  :orderid => 5,
  :amount => 10,
  :customerwmid => CUSTOMER_WMID,
  :storepurse => STORE_PURSE,
  :desc => "Test invoice",
  :address => "Delivery Address"
)
```

### Check state

```ruby
res = @wm.request(:outgoing_invoices,
  :purse => STORE_PURSE,
  :wminvid => @invoice[:id],
  :orderid => @invoice[:orderid],
  :customerwmid => CUSTOMER_WMID,
  :datestart => @invoice[:created_at],
  :datefinish => @invoice[:created_at]
)
if res[:retval].should == 0 && !res[:invoices].empty?
  invoice = res[:invoices].first
  case invoice[:state]
    when 0 then # Not Paid
    when 1 then # Paid with protection
    when 2 then # Payment complete
    when 3 then # Rejected
  end
end
```

## Check purse owner

```ruby
res = @wm.request(:check_user,
  :operation => {
    :type => 2,
    :amount => 100,
    :pursetype => "WMZ"
  },
  :userinfo => {
    :wmid => "123445532523",
    :iname => "Alexander",
    :fname => "Ivanov"
  }
)
```

Also, see spec/* for examples.
