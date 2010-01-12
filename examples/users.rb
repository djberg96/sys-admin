###########################################################################
# users.rb
#
# Sample script to demonstrate some of the various user methods.  Alter
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

user = User.new do |u|
   u.name              = "Foo"
   u.description       = "Test account"
   u.password          = "changeme"
   #u.lockout           = false
   u.disabled          = true
   #u.password_required = true
end

Admin.delete_user(u.name) rescue nil
Admin.add_user(user)

#pp Admin.get_user("Foo")

#Admin.delete_user("Foo")

=begin
user = Admin.get_login

puts "User: #{user}"

Admin.users{ |u|
   pp u
   puts
}

pp Admin.get_user(user)
pp Admin.get_user(501)
=end