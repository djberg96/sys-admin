###########################################################################
# users.rb
#
# Sample script to demonstrate some of the various user methods.  Alter
# as you see fit.
###########################################################################
require "pp"
require "sys/admin"
include Sys

=begin
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

pp Admin.get_user("Foo")

Admin.delete_user("Foo")
=end

user = Admin.get_login

puts "User: #{user}"

sleep 3

Admin.users.each{ |u|
  pp u
  puts
}

pp Admin.get_user(user)
pp Admin.get_user(501)
