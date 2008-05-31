# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

CONFIG["CC"] = "g++ "
#CONFIG["CPP"] = "g++ -E "
#CONFIG["LDSHARED"].gsub!(/^cc /,"g++ ")

# Give it a name
extension_name = 'wmsigner'

# The destination
dir_config(extension_name)

# Do the work
create_makefile(extension_name)

