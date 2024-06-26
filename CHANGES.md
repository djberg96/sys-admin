## 1.8.4 - 12-Jun-2024
* Fixes for DragonFly BSD support.

## 1.8.3 - 20-Apr-2024
* Fixed up the get_group method on most platforms. Previously it was allocating
  slightly more memory than it needed (wrong struct, oops). In addition, the
  error handling wasn't consistent because I can't read a man page properly.
* More specs were added to properly test the get_group updates.
* The github actions test matrix was updated.

## 1.8.2 - 9-Apr-2023
* Lots of rubocop related updates.
* Refactored specs to use shared specs.
* The lastlog key will return nil instead of an empty struct if it can't be read.
* Added more information to the gemspec metadata.
* The rubocop and rubocop-rspec gems are now development dependencies.

## 1.8.1 - 25-Sep-2021
* The users and get_user methods on Darwin now take an optional :lastlog key
  that you can set to false in order to significantly speed up those methods
  at the expense of taking away lastlog information.
* Some internal rspec refactoring.

## 1.8.0 - 26-Aug-2021
* Switched from test-unit to rspec, with some tests refactored. The Rakefile
  and gemspec files were updated accordingly.
* The User and Group classes for the Windows implementation are now properly
  scoped under Sys::Admin instead of just Sys.
* Fixed a bug in the get_user and get_group methods on Windows where the WQL
  it generates internally might not be correct.

## 1.7.6 - 24-Mar-2021
* Changed the implementation for `Admin.get_login` on Linux since the
  underlying `getlogin` C function is unreliable, especially in certain
  virtualized environments.
* Added win32-security back to the gemspec as a dependency for Windows.
  I'm not sure why I removed it, and bundler definitely needs it.
* Fixed some private access modifiers that weren't actually doing anything.

## 1.7.5 - 30-Dec-2020
* Switched from rdoc to markdown since github isn't rendering rdoc properly.

## 1.7.4 - 19-Mar-2020
* Properly include a LICENSE file as per the Apache-2.0 license.

## 1.7.3 - 16-Jan-2020
* Add explicit .rdoc extension to various rdoc files so that they show up
  better in github.
* Some formatting adjustments to the rdoc files.

## 1.7.2 - 28-Jan-2019
* Fixed the license name, was missing a hyphen.
* Fixed the homepage in the gemspec.

## 1.7.1 - 19-Mar-2018
* Fixed deprecation warnings in tests.
* Added gemspec metadata.
* Updated cert again, this one should last 10 years.
 
## 1.7.0 - 21-Feb-2018
* Changed the license to Apache 2.0.
* VERSION constant is now frozen.
* Ignore dependency warnings in gem:create task.
* Minor README updates.
* Updated cert.

## 1.6.4 - 6-Sep-2015
* Added a sys-admin.rb file for convenience.
* Set VERSION in a single place.
* Assume Rubygems 2.x for Rakefile tasks.
* This gem is now signed.

## 1.6.3 - 8-Mar-2014
* The Admin#get_group method now handles groups with very large numbers
  of members more robustly.

## 1.6.2 - 11-Feb-2014
* The User#gid method is now supported on MS Windows. It returns the user's
  primary group ID.

## 1.6.1 - 24-Jan-2014
* Added the Admin.add_group_member and Admin.remove_group member methods. These
  let you add a user to a specific group. Thanks go to Alexey Kolyanov for the
  idea and the code.
* Modified the Admin.configure_user method so that you don't need to know the
  old password. Just pass a single string argument for the new password.
* Fixed a potential encoding issue for the Admin.get_login method on JRuby.
* Updated the gem:create task in the Rakefile.
* Added rake as a development dependency.

## 1.6.0 - 5-Jan-2013
* Converted code to use FFI. This mostly only affects the unix flavors.
* The Admin.users and Admin.groups methods no longer accept a block.
* Some test suite updates.
* Because all code is now pure Ruby, there is longer any need for two
  separate gems. There is now a single, unified gem that works on all
  supported platforms.

## 1.5.6 - 30-Jul-2011
* Fixed issue for non-gnu platforms where it would use the wrong function
  prototype because the Ruby core team took it upon themselves to explicitly
  defined _GNU_SOURCE in config.h in 1.8.7 and later for reasons that baffle me.
* Some tests on Windows are now skipped unless run with elevated security.

## 1.5.5 - 5-Jul-2011
* Modified lastlog handling, and ignore getpwent_r and getgrent_r, on AIX.
  Thanks go to Rick Ohnemus for the spot and patches.
* Explicitly set spec.cpu on Windows to 'universal' in the gem creation task.
* Fixed a bug in the User.get_login and User.get_group methods where the query
  being generated was incorrect if no options were passed. Thanks go to
  Matthew Brown for the spot.

## 1.5.4 - 7-Oct-2010
* Prefer the getlastlogx() function over lastlog() where supported.

## 1.5.3 - 6-Oct-2010
* Refactored the Rakefile. The old installation tasks have been replaced
  with gem build and install tasks. In addition, the platform handling has
  been updated for MS Windows.
* Portions of the gemspec have been moved into the Rakefile gem tasks.
* Deploying the mingw gem by default for MS Windows now.

## 1.5.2 - 2-Aug-2009
* Now compatible with Ruby 1.9.x.
* Added test-unit as a development dependency.

## 1.5.1 - 23-Jul-2009
* Added the User#dir attribute. This attribute contains a user's home
  directory if set, or nil if it isn't.
* User objects returned by the Admin.users method now include the uid.
  Previously only the Admin.get_user method set it.
* Added win32-security as a dependency.
* Changed license to Artistic 2.0.

## 1.5.0 - 29-Mar-2009
* INTERFACE CHANGE (WINDOWS ONLY): The interface for MS Windows has undergone
  a radical change. Most methods now accept a hash of options that are
  passed directly to the underlying WMI class. Please see the documentation
  for details.
* Now works on various BSD flavors.
* Added the User#groups method. This returns an array of groups that the
  user belongs to. Suggestion inspired by Gonzalo Garramuno.
* Added the Group#members method. The returns an array of users that the
  group contains.
* Changed User#class to User#access_class for UNIX flavors to avoid
  conflicts with the Ruby core Object method.
* Added more tests and renamed the test files.
* Removed an unnecessary function call where a platform might try to
  get lastlog information even if the lastlog.h or utmp.h headers couldn't
  be found.

## 1.4.4 - 19-Nov-2008
* Added the User#uid method for MS Windows (which is just the user's relative
  identifier).
* Now requires test-unit 2.x.
* Some updates to the test suite to take advantage of test-unit 2.x features.
* Some minor gemspec tweaks.

## 1.4.3 - 2-Mar-2008
* The block form of Admin.users now properly ensures that endpwent() is
  called. Likewise, the block form of Admin.groups now properly ensures
  that endgrent() is called. This would only have been an issue if you
  broke out of the block before it terminated.
* The AdminError class is now Admin::Error.
* Some internal directory layout changes.

## 1.4.2 - 26-Jun-2007
* Fixed a bug in the Admin.get_login method where it would return junk
  if the underlying getlogin() function failed (Unix). Thanks go to Gonzalo
  Garramuno for the spot. This bug also resulted in some refactoring of the
  underlying C code.
* Removed the install.rb file. The logic in that file has been moved directly
  into the Rakefile.

## 1.4.1 - 21-Mar-2007
* Bug fix for OS X. Thanks go to an anonymous user for the spot.
* Added a Rakefile. Building, testing and installing should now use the
  Rake tasks (for non-gem installs).
* Much more inline documentation, especially for User and Group attributes.

## 1.4.0 - 20-Jan-2007
* Added the following methods: add_local_user, config_local_user,
  delete_local_user, add_global_group, config_global_group, and
  delete_global_group.  MS Windows only at the moment.
* Added corresponding tests.
* Added much more inline documentation.
* Major refactoring of the get_lastlog_info helper function in admin.h.  This
  fixed a major bug in some flavors of Linux where the Admin.users method
  could go into an infinite loop.  It also fixed some minor bugs where console
  and host values were sometimes filled with junk characters.
* Added the User#change attribute, and a check for the pw_change struct member
  in the extconf.rb file.
* The User#expire attribute is now handled as a Time object instead of an
  integer.
* Renamed tc_win32.rb to tc_windows.rb

## 1.3.1 - 29-Jun-2005
* Fixed a bug where the inability to read the lastlog file caused an error.
  From now on that error is ignored, and the lastlog attributes of the User
  object are set to nil.
* Added a beta version of Admin.delete_user (Windows only).

## 1.3.0 - 3-Jun-2005
* Bug fixes for Linux.
* Removed the version.h file - no longer needed since the Win32 version is
  pure Ruby.

## 1.2.0 - 30-Apr-2005
* Replaced the Win32 version with a pure Ruby version that uses Win32API and
  win32ole + WMI.
* The LocalGroup class no longer exists in the Win32 version.  Instead, it is
  now an attribute of a Group object.  The issue was forced by WMI.
* The default for users and groups on Win32 systems is now local rather than
  global.  See the documentation for why you probably don't want to iterate
  over global accounts.
* Corresponding doc changes and test suite changes.

## 1.1.0 - 1-Apr-2005
* Fixed bug where a segfault could occur when trying to retrieve a user or
  group by an ID that didn't exist (Unix).
* Added tests for intentional failures.
* Added lastlog information tothe User class (Unix).
* Modified the way User objects are created internally (Unix).
* Fixed a bug in the User#shell attribute (Unix).

## 1.0.0 - 25-Mar-2005
* Initial release
