#include <limits.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <pwd.h>
#include <grp.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#define SYS_ADMIN_VERSION "1.5.7"

#if defined(__MACH__) || defined(__APPLE__)
#define __BSD__
#endif

#if defined(__FreeBSD__) || defined (__NetBSD__) || defined(__OpenBSD__) || defined(__DragonFly__)
#define __BSD__
#endif

#if defined(HAVE_USERSEC_H)
#include <usersec.h>
#else
#if defined(HAVE_UTMPX_H) && defined(HAVE_GETLASTLOGX)
#include <utmpx.h>
#else
#ifdef HAVE_LASTLOG_H
#include <lastlog.h>
#else
#include <utmp.h>
#endif
#endif
#endif

#ifndef _POSIX_LOGIN_NAME_MAX
#define _POSIX_LOGIN_NAME_MAX 9
#endif

// BSD platforms are problematic with explicit inclusion of unistd.h
#if defined(__BSD__)
#define USER_BUF_SIZE 1024
#else
#ifdef _SC_GETPW_R_SIZE_MAX
#define USER_BUF_SIZE (sysconf(_SC_GETPW_R_SIZE_MAX))
#else
#define USER_BUF_SIZE 1024
#endif
#endif

// BSD platforms are problematic with explicit inclusion of unistd.h
#if defined(__BSD__)
#define GROUP_BUF_SIZE 7296
#else
#ifdef _SC_GETGR_R_SIZE_MAX
#define GROUP_BUF_SIZE (sysconf(_SC_GETGR_R_SIZE_MAX))
#else
#define GROUP_BUF_SIZE 7296
#endif
#endif

#ifndef _PATH_LASTLOG
#define _PATH_LASTLOG "/var/adm/lastlog"
#endif

/* Function prototypes */
static VALUE admin_users_cleanup();
static VALUE admin_groups_cleanup();
static VALUE get_user(struct passwd* p);
static VALUE get_group(struct group* g);
int get_lastlog_info(struct passwd* p, VALUE v_value);

VALUE cUser, cGroup, cAdminError;

/*
 * :no-doc:
 *
 * Helper function that returns a User object based on user ID.
 */
static VALUE get_user_by_num(VALUE v_uid){
  volatile VALUE v_user;
  uid_t uid = NUM2INT(v_uid);

#ifdef HAVE_GETPWUID_R
  char buf[USER_BUF_SIZE];
  struct passwd pwd;
  struct passwd* pwdbuf;

  if(getpwuid_r(uid, &pwd, buf, sizeof(buf), &pwdbuf) != 0)
    rb_raise(cAdminError, "%s", strerror(errno));

  if(!pwdbuf)
    rb_raise(cAdminError, "no user found for %i:", uid);

  v_user = get_user(pwdbuf);
#elif HAVE_GETPWUID
  struct passwd* pwd;
  if( (pwd = getpwuid(uid)) == NULL)
    rb_raise(cAdminError, "no user found for: %i", uid);

  v_user = get_user(pwd);
#else
  rb_raise(rb_eNotImpError, "getting user by user ID not supported");
#endif

  return v_user;
}

/*
 * :no-doc:
 *
 * Helper function that returns a User object based on name.
 */
static VALUE get_user_by_name(VALUE v_name){
   volatile VALUE v_user;
   SafeStringValue(v_name);

#ifdef HAVE_GETPWNAM_R
   char buf[USER_BUF_SIZE];
   struct passwd pwd;
   struct passwd* pwdbuf;

   if(getpwnam_r(RSTRING_PTR(v_name), &pwd, buf, sizeof(buf), &pwdbuf) != 0)
      rb_raise(cAdminError, "%s", strerror(errno));

   if(!pwdbuf)
      rb_raise(cAdminError, "no user found for %s", StringValuePtr(v_name));

   v_user = get_user(pwdbuf);
#elif HAVE_GETPWNAM
   struct passwd* pwd;
   if( (pwd = getpwnam(RSTRING(v_name)->ptr)) == NULL)
      rb_raise(cAdminError, "no user found for %s", StringValuePtr(v_name));

   v_user = get_user(pwd);
#else
   rb_raise(rb_eNotImpError, "getting user by name not supported");
#endif

   return v_user;
}

/*
 * :no-doc:
 *
 * Helper function that returns a Group object based on group ID.
 */
static VALUE get_group_by_num(VALUE v_gid){
   volatile VALUE v_group;
   gid_t gid = NUM2INT(v_gid);

#ifdef HAVE_GETGRGID_R
   char buf[GROUP_BUF_SIZE];
   struct group grp;
   struct group* grpbuf;

   if(getgrgid_r(gid, &grp, buf, sizeof(buf), &grpbuf) != 0)
      rb_raise(cAdminError, "getgrgid_r() failed: %s", strerror(errno));

   if(!grpbuf)
      rb_raise(cAdminError, "no group found for group ID: %i", gid);

   v_group = get_group(grpbuf);
#elif HAVE_GETGRGID
   struct group* grp;
   if( (grp = getgrgid(gid)) == NULL)
      rb_raise(cAdminError, "no group found for group ID: %i", gid);

   v_group = get_group(grp);
#else
   rb_raise(rb_eNotImpError, "getting group by group ID not supported");
#endif

   return v_group;
}

/*
 * :no-doc:
 *
 * Helper function that returns a Group object based on group name.
 */
static VALUE get_group_by_name(VALUE v_name){
   volatile VALUE v_group = Qnil;
   SafeStringValue(v_name);
#ifdef HAVE_GETGRNAM_R
   char buf[GROUP_BUF_SIZE];
   struct group grp;
   struct group* grpbuf;

   if(getgrnam_r(RSTRING_PTR(v_name), &grp, buf, sizeof(buf), &grpbuf) != 0)
      rb_raise(cAdminError, "%s", strerror(errno));

   if(!grpbuf)
      rb_raise(cAdminError, "no group found for: %s", StringValuePtr(v_name));

   v_group = get_group(grpbuf);
#elif HAVE_GETGRNAM
   struct group* grp
   if((grp = getgrnam(RSTRING(v_name)->ptr)) == NULL)
      rb_raise(cAdminError, "no group found for: %s", StringValuePtr(v_name));

   v_group = get_group(grp);
#else
   rb_raise(rb_eNotImpError, "get_group is not supported on this platform");
#endif

   return v_group;
}

/*
 * :no-doc:
 *
 * Helper function that turns a struct passwd into a User object.
 */
static VALUE get_user(struct passwd* pwd){
   VALUE v_user = rb_funcall(cUser, rb_intern("new"), 0, 0);

   rb_iv_set(v_user, "@name", rb_str_new2(pwd->pw_name));
   rb_iv_set(v_user, "@uid", INT2FIX(pwd->pw_uid));
   rb_iv_set(v_user, "@gid", INT2FIX(pwd->pw_gid));
   rb_iv_set(v_user, "@dir", rb_str_new2(pwd->pw_dir));
   rb_iv_set(v_user, "@shell", rb_str_new2(pwd->pw_shell));

#ifdef HAVE_ST_PW_PASSWD
   rb_iv_set(v_user, "@passwd", rb_str_new2(pwd->pw_passwd));
#endif

/* TODO: Fix this, or just set it to nil */
#ifdef HAVE_ST_PW_AGE
   rb_iv_set(v_user, "@age", INT2FIX(pwd->pw_age));
#endif

#ifdef HAVE_ST_PW_COMMENT
   rb_iv_set(v_user, "@comment", rb_str_new2(pwd->pw_comment));
#endif

#ifdef HAVE_ST_PW_GECOS
   rb_iv_set(v_user, "@gecos", rb_str_new2(pwd->pw_gecos));
#endif

#ifdef HAVE_ST_PW_QUOTA
   rb_iv_set(v_user, "@quota", INT2FIX(pwd->pw_quota));
#endif

#ifdef HAVE_ST_PW_CLASS
   rb_iv_set(v_user, "@access_class", rb_str_new2(pwd->pw_class));
#endif

#ifdef HAVE_ST_PW_EXPIRE
   rb_iv_set(v_user, "@expire", rb_time_new(pwd->pw_expire, 0));
#endif

#ifdef HAVE_ST_PW_CHANGE
   rb_iv_set(v_user, "@change", rb_time_new(pwd->pw_change, 0));
#endif

#if defined(HAVE_LASTLOG_H) || defined(HAVE_UTMP_H) || defined(HAVE_USERSEC_H)
   get_lastlog_info(pwd, v_user);
#endif

   return v_user;
}

/*
 * :no-doc:
 *
 * Helper function that turns a User object into a struct passwd.
 */
void get_user_from_value(VALUE v_user, struct passwd* pwd){

   VALUE v_name  = rb_iv_get(v_user, "@name");
   VALUE v_uid   = rb_iv_get(v_user, "@uid");
   VALUE v_gid   = rb_iv_get(v_user, "@gid");
   VALUE v_dir   = rb_iv_get(v_user, "@dir");
   VALUE v_shell = rb_iv_get(v_user, "@shell");

   if(NIL_P(v_name))
      rb_raise(cAdminError, "user name cannot be nil");

   if(!NIL_P(v_uid))
      pwd->pw_uid = NUM2INT(v_uid);

   if(!NIL_P(v_gid))
      pwd->pw_gid = NUM2INT(v_gid);

   if(!NIL_P(v_dir)){
      SafeStringValue(v_dir);
      pwd->pw_dir = StringValuePtr(v_dir);
   }

   if(!NIL_P(v_shell)){
      SafeStringValue(v_shell);
      pwd->pw_shell = StringValuePtr(v_shell);
   }

#ifdef HAVE_ST_PW_PASSWD
   VALUE v_passwd = rb_iv_get(v_user, "@passwd");
   if(!NIL_P(v_passwd)){
      SafeStringValue(v_passwd);
      pwd->pw_passwd = StringValuePtr(v_passwd);
   }
#endif

/* TODO: Fix this or just set it to nil */
#ifdef HAVE_ST_PW_AGE
   VALUE v_age = rb_iv_get(v_user, "@age");
   if(!NIL_P(v_age))
      pwd->pw_age = (char*)NUM2INT(v_age);
#endif

#ifdef HAVE_ST_PW_COMMENT
   VALUE v_comment = rb_iv_get(v_user, "@comment");
   if(!NIL_P(v_comment)){
      SafeStringValue(v_comment);
      pwd->pw_comment = StringValuePtr(v_comment);
   }
#endif

#ifdef HAVE_ST_PW_GECOS
   VALUE v_gecos = rb_iv_get(v_user, "@gecos");
   if(!NIL_P(v_gecos)){
      SafeStringValue(v_gecos);
      pwd->pw_gecos = StringValuePtr(v_gecos);
   }
#endif

#ifdef HAVE_ST_PW_QUOTA
   VALUE v_quota = rb_iv_get(v_user, "@quota");
   if(!NIL_P(v_quota))
      pwd->pw_quota = NUM2INT(v_quota);
#endif

#ifdef HAVE_ST_PW_CLASS
   VALUE v_class = rb_iv_get(v_user, "@access_class");
   if(!NIL_P(v_class)){
      SafeStringValue(v_class);
      pwd->pw_class = StringValuePtr(v_class);
   }
#endif

#ifdef HAVE_ST_PW_EXPIRE
   VALUE v_expire = rb_iv_get(v_user, "@expire");
   v_expire = rb_funcall(v_expire, rb_intern("to_i"), 0, 0);
   if(!NIL_P(v_expire))
      pwd->pw_expire = NUM2ULONG(v_expire);
#endif

#ifdef HAVE_ST_PW_CHANGE
   VALUE v_change = rb_iv_get(v_user, "@change");
   v_change = rb_funcall(v_change, rb_intern("to_i"), 0, 0);
   if(!NIL_P(v_change))
      pwd->pw_change = NUM2ULONG(v_change);
#endif

}

/*
 * :no-doc:
 *
 * Helper function that turns a struct grp into a Group object.
 */
static VALUE get_group(struct group* g){
   VALUE v_group = rb_funcall(cGroup,rb_intern("new"),0,0);
   VALUE v_array = rb_ary_new();
   char **my_gr_mem = g->gr_mem;

   /* Return the members as an Array of Strings */
   while(*my_gr_mem){
      rb_ary_push(v_array, rb_str_new2(*my_gr_mem));
      my_gr_mem++;
   }

   rb_iv_set(v_group, "@name", rb_str_new2(g->gr_name));
   rb_iv_set(v_group, "@gid", INT2FIX(g->gr_gid));
   rb_iv_set(v_group, "@members", v_array);
#ifdef HAVE_ST_GR_PASSWD
   rb_iv_set(v_group, "@passwd", rb_str_new2(g->gr_passwd));
#endif

   return v_group;
}

/*
 * :no-doc:
 *
 * Helper function that turns a Group object into a struct group.
 */
void get_group_from_value(VALUE v_group, struct group* grp){
   char** members = malloc(sizeof(char*));
   VALUE v_name   = rb_iv_get(v_group, "@name");
   VALUE v_gid    = rb_iv_get(v_group, "@gid");
   VALUE v_mem    = rb_iv_get(v_group, "@members");
   VALUE v_passwd = rb_iv_get(v_group, "@passwd");
   int i = 0;

   if(NIL_P(v_name))
      rb_raise(cAdminError, "group name must be set");

   SafeStringValue(v_name);
   grp->gr_name = StringValuePtr(v_name);

   if(!NIL_P(v_gid))
      grp->gr_gid = NUM2INT(v_gid);

   if(!NIL_P(v_mem)){
      VALUE v_value;
      while((v_value = rb_ary_shift(v_mem)) != Qnil){
         members[i] = StringValuePtr(v_value);
         i++;
      }
      members[i] = '\0';
      grp->gr_mem = members;
   }

#ifdef HAVE_ST_GR_PASSWD
   if(!NIL_P(v_passwd)){
      SafeStringValue(v_passwd);
      grp->gr_passwd = StringValuePtr(v_passwd);
   }
#endif

   free(members);
}

/*
 * :no-doc:
 *
 * Helper function that gets lastlog information for the User object.
 *--
 * Note that even if the platform supports lastlog information, it can
 * still be empty or nil.
 */
int get_lastlog_info(struct passwd* pwd, VALUE v_user){
#ifdef HAVE_USERSEC_H
  char *lasthost;
  int lasttime;
  char *lasttty;

  if (setuserdb(S_READ) == -1) {
    return -1;
  }

  if (getuserattr(pwd->pw_name, S_LASTTIME, &lasttime, SEC_INT) == -1
      || getuserattr(pwd->pw_name, S_LASTTTY, &lasttty, SEC_CHAR) == -1
      || getuserattr(pwd->pw_name, S_LASTHOST, &lasthost, SEC_CHAR) == -1) {
    enduserdb();
    return -1;
  }

  rb_iv_set(v_user, "@login_time", rb_time_new(lasttime, 0));
  rb_iv_set(v_user, "@login_device", rb_str_new2(lasttty));
  rb_iv_set(v_user, "@login_host", rb_str_new2(lasthost));
  enduserdb();
#else
#ifdef HAVE_GETLASTLOGX
  struct lastlogx log;

  if(getlastlogx(pwd->pw_uid, &log)){
    rb_iv_set(v_user, "@login_time", rb_time_new(log.ll_tv.tv_sec, log.ll_tv.tv_usec));
    rb_iv_set(v_user, "@login_device", rb_str_new2(log.ll_line));
    rb_iv_set(v_user, "@login_host", rb_str_new2(log.ll_host));
  }
#else
  int fd;
  ssize_t bytes_read;
  struct lastlog log;
  int ll_size = sizeof(struct lastlog);

  /* The lastlog information is not necessarily readable by all users, so
   * ignore open() errors if they occur.
   */
  if((fd = open(_PATH_LASTLOG, O_RDONLY)) == -1)
    return -1;

  if((bytes_read = pread(fd, &log, ll_size, pwd->pw_uid * ll_size)) < 0){
    close(fd);
    rb_raise(cAdminError, "%s", strerror(errno));
  }

  close(fd);

  if(bytes_read > 0){
#ifdef HAVE_ST_LL_TIME
    if(log.ll_time != 0)
      rb_iv_set(v_user, "@login_time", rb_time_new(log.ll_time, 0));
#endif
    rb_iv_set(v_user, "@login_device", rb_str_new2(log.ll_line));
    rb_iv_set(v_user, "@login_host", rb_str_new2(log.ll_host));
  }
#endif
#endif

  return 0;
}

/*
 * :no-doc:
 *
 * This function is used for an rb_ensure() call where we need to make sure
 * that endpwent() is called in the block form of Admin.groups.
 */
static VALUE admin_groups_cleanup(){
  endgrent();
  return Qnil;
}

/*
 * :no-doc:
 *
 * This function is used for an rb_ensure() call where we need to make sure
 * that endpwent() is called in the block form of Admin.users.
 */
static VALUE admin_users_cleanup(){
  endpwent();
  return Qnil;
}
