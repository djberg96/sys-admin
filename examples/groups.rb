###########################################################################
# groups.rb
#
# Sample script to demonstrate some of the various group methods.  Alter
# as you see fit.
###########################################################################
base = File.basename(Dir.pwd)

if base == "examples" || base =~ /sys-admin.*/
   require "ftools"
   Dir.chdir("..") if base == "examples"
   Dir.mkdir("sys") unless File.exists?("sys")
   if RUBY_PLATFORM.match("mswin")
      File.copy("lib/sys/admin.rb", "sys/admin.rb")
   else
      File.copy("admin.so","sys") if File.exists?("admin.so")
   end
   $LOAD_PATH.unshift(Dir.pwd)
end

require "pp"
require "sys/admin"
include Sys

if PLATFORM.match("mswin")
   pp Admin.get_group("guests")
   pp Admin.get_group(513)
else
   pp Admin.get_group("adm")
   pp Admin.get_group(7)
end

Admin.groups{ |g|
   pp g
   puts
}

# This should raise an error
Admin.get_group("fofofofof")
