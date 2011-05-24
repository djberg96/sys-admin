require "mkmf"

if RUBY_PLATFORM.match('mswin')
  STDERR.puts "Use the 'rake install' task to install on MS Windows."
  STDERR.puts "Exiting. The sys-admin package was NOT installed."
  exit
else
  dir_config('admin')

  have_func("getlogin_r")
  have_func("getlogin")
  have_func("getenv")

  have_func("getpwuid_r")
  have_func("getpwuid")
  have_func("getpwnam_r")
  have_func("getpwnam")
  have_func("getpwent_r")
  have_func("getpwent")

  have_func("getgrgid_r")
  have_func("getgrgid")
  have_func("getgrnam_r")
  have_func("getgrnam")
  have_func("getgrent_r")
  have_func("getgrent")

  have_struct_member("struct passwd", "pw_gecos", "pwd.h")
  have_struct_member("struct passwd", "pw_change", "pwd.h")
  have_struct_member("struct passwd", "pw_quota", "pwd.h")
  have_struct_member("struct passwd", "pw_age", "pwd.h")
  have_struct_member("struct passwd", "pw_class", "pwd.h")
  have_struct_member("struct passwd", "pw_comment", "pwd.h")
  have_struct_member("struct passwd", "pw_expire", "pwd.h")
  have_struct_member("struct passwd", "pw_passwd", "pwd.h")

  have_struct_member("struct group", "gr_passwd", "grp.h")

  if have_header("usersec.h")
    have_func("getuserattr", "usersec.h")
  else
    utmp    = have_header("utmp.h")
    lastlog = have_header("lastlog.h")

    if have_header("utmpx.h")
      have_func("getlastlogx")
    end

    if utmp || lastlog
      have_struct_member(
        "struct lastlog",
        "ll_time",
        ["utmp.h", "time.h", "lastlog.h"]
      )
    end
  end

  $CFLAGS += " -D_POSIX_PTHREAD_SEMANTICS"

  if RUBY_PLATFORM =~ /linux|bsd/i
    $CFLAGS += " -D_GNU_SOURCE -D_REENTRANT"
  end
end

create_makefile('sys/admin', 'sys')
