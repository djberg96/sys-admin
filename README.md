[![Ruby](https://github.com/djberg96/sys-admin/actions/workflows/ruby.yml/badge.svg)](https://github.com/djberg96/sys-admin/actions/workflows/ruby.yml)

## Description
The sys-admin library is a unified, cross platform replacement for the Etc module.
   
## Installation
`gem install sys-admin`

## Adding the trusted cert
`gem cert --add <(curl -Ls https://raw.githubusercontent.com/djberg96/sys-admin/main/certs/djberg96_pub.pem)`

## Synopsis
```ruby
require 'sys/admin' # or sys-admin
include Sys

# Returns an Array of User objects
a = Admin.users

# Returns an Array of Group objects
g = Admin.groups

# Get information about a particular user
p Admin.get_user("nobody")
p Admin.get_user("nobody", :localaccount => true)

# Get information about a particular group
p Admin.get_group("adm")
p Admin.get_group("adm", :localaccount => true)
```

## Admin
  `Admin.get_login`

Returns the user name (only) of the current login.

```
Admin.get_user(name, options = {})
Admin.get_user(uid, options = {})
```

Returns a User object based on `name` or `uid`. The `options` hash is
for MS Windows only, and allows you to restrict the search based on the
options you provide, e.g. 'domain' or 'localaccount'.
   
```
Admin.get_group(name, options = {})
Admin.get_group(gid, options = {})
```

Returns a Group object based on `name` or `uid`. The `options` hash is
for MS Windows only, and allows you to restrict the search based on the
options you provide, e.g. 'domain' or 'localaccount'.

`Admin.groups(options = {})`

Returns an Array of Group objects.

The `options` hash is for MS Windows only, and allows you to restrict the
search based on the options you provide, e.g. 'domain' or 'localaccount'.

`Admin.users(options = {})`

Returns an Array of User objects.
   
The `options` hash is for MS Windows only, and allows you to restrict the
search based on the options you provide, e.g. 'domain' or 'localaccount'.
   
## User class
### User (Windows)
The User class has the following attributes on MS Windows systems:
	
  * account_type
  * caption
  * description
  * domain
  * password
  * full_name
  * gid
  * install_date
  * name
  * sid
  * status
  * disabled?
  * local?
  * lockout?
  * password_changeable?
  * password_expires?
  * password_required?
  * uid
     
### User (Unix)
The User class has the following attributes on Unix systems:
	
  * name
  * passwd
  * uid
  * gid
  * dir
  * shell
  * gecos
  * quota
  * age
  * class
  * comment
  * change
  * expire

## Group Classes
### Group (Windows)
The Group class has the following attributes on MS Windows systems:
	
  * caption
  * description
  * domain
  * install_date
  * name
  * sid
  * status
  * gid
  * local?
	
### Group (Unix)
The Group class has the following attributes on Unix systems:
	
  * name
  * gid
  * members
  * passwd

## Error Classes
`Admin::Error < StandardError`

Raised if anything goes wrong with any of the above methods.

## Developer's Notes
### MS Windows
The Windows version now uses a win32ole + WMI approach to getting
information.  This means that the WMI service must be running on the
target machine in order to work (which it is, by default).
	
### UNIX
The underlying implementation is similar to core Ruby's Etc implementation.
But, in addition to the different interface, I use the re-entrant version
of the appropriate functions when available.

### OSX
The slowdown for collecting lastlog information on OSX seems to have gotten
progressively worse over time. Do not be surprised by significant slowdowns
if you opt to collect it.

## Future Plans
* Make the User and Group objects comparable.
* Add ability to add, configure and delete users on Unix platforms.

## Known Bugs
None that I'm aware of. If you find any, please log them on the project page at:

  https://github.com/djberg96/sys-admin

## License
Apache-2.0

## Copyright
(C) 2005-2024, Daniel J. Berger
All Rights Reserved

## Author
Daniel J. Berger
