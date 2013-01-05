###########################################################################
# groups.rb
#
# Sample script to demonstrate some of the various group methods.  Alter
# as you see fit.
###########################################################################
require "pp"
require "sys/admin"
include Sys

if File::ALT_SEPARATOR
  pp Admin.get_group("guests")
  pp Admin.get_group(513)
else
  pp Admin.get_group("admin")
  pp Admin.get_group(7)
end

sleep 3

Admin.groups.each{ |g|
   pp g
   puts
}

# This should raise an error
Admin.get_group("fofofofof")
