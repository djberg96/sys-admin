#include "ruby.h"
#include "admin.h"

#ifndef RSTRING_PTR
#define RSTRING_PTR(v) (RSTRING(v)->ptr)
#define RSTRING_LEN(v) (RSTRING(v)->len)
#endif

#ifndef RARRAY_PTR
#define RARRAY_PTR(v) (RARRAY(v)->ptr)
#define RARRAY_LEN(v) (RARRAY(v)->len)
#endif

/*
 * call-seq:
 *    User.new
 *    User.new{ |user| ... }
 *
 * Creates and returns a User object, which encapsulates the information
 * typically found within an /etc/passwd entry, i.e. a struct passwd.
 *
 * If a block is provided, yields the object back to the block.
 */
static VALUE user_init(VALUE self){
   if(rb_block_given_p())
      rb_yield(self);

   return self;
}

/*
 * call-seq:
 *    Group.new
 *    Group.new{ |user| ... }
 *
 * Creates and returns a Group object, which encapsulates the information
 * typically found within an /etc/group entry, i.e. a struct group.
 *
 * If a block is provided, yields the object back to the block.
 */
static VALUE group_init(VALUE self){
   if(rb_block_given_p())
      rb_yield(self);

   return self;
}

/*
 * call-seq:
 *    Sys::Admin.get_login
 *
 * Returns the login for the process. If this is called from a process that
 * has no controlling terminal, then it resorts to returning the "LOGNAME" or
 * "USER" environment variable.  If neither of those is defined, then nil
 * is returned.
 *
 * Note that this method will _probably_ return the real user login, but may
 * return the effective user login. YMMV depending on your platform and how
 * the program is run.
 */
static VALUE admin_get_login(VALUE klass){
#ifdef HAVE_GETLOGIN_R
   char login[_POSIX_LOGIN_NAME_MAX];

   if(!getlogin_r(login, _POSIX_LOGIN_NAME_MAX))
      return rb_str_new2(login);
#elif HAVE_GETLOGIN
   char* login = getlogin();

   if(login)
      return rb_str_new2(login);
#endif

#ifdef HAVE_GETPWUID_R
   uid_t uid;
   char buf[USER_BUF_SIZE];
   struct passwd pwd;
   struct passwd* pwdbuf;

   uid = getuid();

   if(getpwuid_r(uid, &pwd, buf, USER_BUF_SIZE, &pwdbuf) != 0)
      return rb_str_new2(pwdbuf->pw_name);
#elif HAVE_GETPWUID
   uid_t uid;
   struct passwd* pwd;

   uid = getuid();

   if((pwd = getpwuid(uid)))
      return rb_str_new2(pwd->pw_name);
#endif

#ifdef HAVE_GETENV
   char* user = getenv("LOGNAME");

   if(user){
      return rb_str_new2(user);
   }
   else{
      user = getenv("USER");
      if(user)
         return rb_str_new2(user);
   }
#endif

   return Qnil;
}

/* call-seq:
 *    Admin.get_user(name)
 *    Admin.get_user(uid)
 *
 * Returns a User object for the given +name+ or +uid+. Raises an Admin::Error
 * if a user cannot be found for that name or user ID.
 */
static VALUE admin_get_user(VALUE klass, VALUE v_value){
   VALUE v_user;

   if(FIXNUM_P(v_value))
      v_user = get_user_by_num(v_value);
   else
      v_user = get_user_by_name(v_value);

   return v_user;
}

/* call-seq:
 *    Admin.get_group(name)
 *    Admin.get_group(gid)
 *
 * Returns a Group object for the given +name+ or +gid+. Raises an Admin::Error
 * if a group cannot be found for that name or GID.
 *
 *--
 * Developer's Note:
 *
 * I generally oppose method overloading like this, but for this method, and
 * for only two types, I can live with it for the added convenience it
 * provides.
 */
static VALUE admin_get_group(VALUE klass, VALUE v_value){
   VALUE v_group;

   if(FIXNUM_P(v_value))
      v_group = get_group_by_num(v_value);
   else
      v_group = get_group_by_name(v_value);

   return v_group;
}

/*
 * :no-doc:
 *
 * This is the main body of the Admin.groups method. It is wrapped separately
 * for the sake of an rb_ensure() call.
 */
static VALUE admin_groups_body(VALUE klass){
   VALUE v_array = Qnil;

   if(!rb_block_given_p())
      v_array = rb_ary_new();

   setgrent();

#ifdef HAVE_GETGRENT_R
   struct group grp;
   char buf[GROUP_BUF_SIZE];
#ifdef _GNU_SOURCE
   struct group* grp_p;

   while(!getgrent_r(&grp, buf, GROUP_BUF_SIZE, &grp_p)){
      if(grp_p == NULL)
         break;

      if(rb_block_given_p())
         rb_yield(get_group(grp_p));
      else
         rb_ary_push(v_array, get_group(grp_p));
   }
#else
   while(getgrent_r(&grp, buf, GROUP_BUF_SIZE) != NULL){
      if(rb_block_given_p())
         rb_yield(get_group(&grp));
      else
         rb_ary_push(v_array, get_group(&grp));
   }
#endif
#elif HAVE_GETGRENT
   struct group* grp;
   while((grp = getgrent()) != NULL){
      if(rb_block_given_p())
         rb_yield(get_group(grp));
      else
         rb_ary_push(v_array, get_group(grp));
   }
#else
   rb_raise(rb_eNotImpError, "groups method not supported on this platform");
#endif

   return v_array; /* Nil or an array */
}

/* call-seq:
 *    Admin.groups
 *    Admin.groups{ |group| ... }
 *
 * In block form, yields a Group object for each group on the system. In
 * non-block form, returns an Array of Group objects.
 */
static VALUE admin_groups(VALUE klass){
   return rb_ensure(admin_groups_body, rb_ary_new3(1, klass),
      admin_groups_cleanup, Qnil
   );
}

/*
 * :no-doc:
 *
 * This is the main body of the Admin.users method. It is wrapped separately
 * for the sake of an rb_ensure() call.
 */
static VALUE admin_users_body(VALUE klass){
   VALUE v_array = Qnil;

   if(!rb_block_given_p())
      v_array = rb_ary_new();

   setpwent();

#ifdef HAVE_GETPWENT_R
   struct passwd pwd;
   char buf[USER_BUF_SIZE];

#ifdef _GNU_SOURCE
   struct passwd* pwd_p;

   while(!getpwent_r(&pwd, buf, USER_BUF_SIZE, &pwd_p)){
      if(pwd_p == NULL)
         break;

      if(rb_block_given_p())
         rb_yield(get_user(pwd_p));
      else
         rb_ary_push(v_array, get_user(pwd_p));
   }
#else
   while(getpwent_r(&pwd, buf, USER_BUF_SIZE) != NULL){
      if(rb_block_given_p())
         rb_yield(get_user(&pwd));
      else
         rb_ary_push(v_array, get_user(&pwd));
   }
#endif
#elif HAVE_GETPWENT
   struct passwd* pwd;

   while((pwd = getpwent()) != NULL){
      if(rb_block_given_p())
         rb_yield(get_user(pwd));
      else
         rb_ary_push(v_array, get_user(pwd));
   }
#else
   rb_raise(rb_eNotImpError, "users method not supported on this platform");
#endif

   return v_array; /* Nil or an array */
}


/* call-seq:
 *    Admin.users
 *    Admin.users{ |user| ... }
 *
 * In block form, yields a User object for each user on the system. In
 * non-block form, returns an Array of User objects.
 */
static VALUE admin_users(VALUE klass){
   return rb_ensure(admin_users_body, rb_ary_new3(1, klass),
      admin_users_cleanup, Qnil
   );
}

/* call-seq:
 *    User#groups # => ['staff', 'admin', ...]
 *
 * Returns an array of groups the user belongs to.
 */
static VALUE user_groups(VALUE self){
   VALUE v_groups, v_group, v_users, v_group_name, v_name, v_result;
   int i;

   v_name   = rb_funcall(self, rb_intern("name"), 0, 0);
   v_result = rb_ary_new();
   v_groups = admin_groups(self);

   /* Iterate over each group, checking its members. If the members includes
    * the user name, we have a match.
    */
   if(!NIL_P(v_groups)){
      for(i = 0; i < RARRAY_LEN(v_groups); i++){
         v_group = RARRAY_PTR(v_groups)[i];
         v_users = rb_funcall(v_group, rb_intern("members"), 0, 0);

         if(RTEST(rb_funcall(v_users, rb_intern("include?"), 1, v_name))){
            v_group_name = rb_funcall(v_group, rb_intern("name"), 0, 0);
            rb_ary_push(v_result, v_group_name);
         }
      }
   }

   return v_result;
}

/*
 * The Sys::Admin class encapsulates typical operations surrounding the query
 * of user and group information.
 */
void Init_admin(){
   VALUE mSys, cAdmin;

   /* The Sys module is used primarily as a namespace for Sys::Admin */
   mSys = rb_define_module("Sys");

   /* A unified, cross platform replacement for the Etc module. */
   cAdmin = rb_define_class_under(mSys, "Admin", rb_cObject);

   /* Encapsulates information typically found in /etc/passwd */
   cUser = rb_define_class_under(mSys, "User",  rb_cObject);

   /* Encapsulates information typically found in /etc/group */
   cGroup = rb_define_class_under(mSys, "Group", rb_cObject);

   /* Error raised if any of the Sys::Admin methods fail */
   cAdminError = rb_define_class_under(cAdmin, "Error", rb_eStandardError);

   /* Class Methods */
   rb_define_singleton_method(cAdmin, "get_login", admin_get_login, 0);
   rb_define_singleton_method(cAdmin, "get_user", admin_get_user, 1);
   rb_define_singleton_method(cAdmin, "get_group", admin_get_group, 1);
   rb_define_singleton_method(cAdmin, "users", admin_users, 0);
   rb_define_singleton_method(cAdmin, "groups", admin_groups, 0);

   /* Instance Methods */
   rb_define_method(cUser, "initialize", user_init, 0);
   rb_define_method(cUser, "groups", user_groups, 0);
   rb_define_method(cGroup,"initialize", group_init, 0);

   /* User Attributes */

   /* The user name associated with the account */
   rb_define_attr(cUser, "name", 1, 1);

   /* The user's encrypted password. Deprecated in favor of /etc/shadow */
   rb_define_attr(cUser, "passwd", 1, 1);

   /* The user's user ID */
   rb_define_attr(cUser, "uid", 1, 1);

   /* The user's primary group ID */
   rb_define_attr(cUser, "gid", 1, 1);

   /* The absolute pathname of the user's home directory */
   rb_define_attr(cUser, "dir", 1, 1);

   /* The user's login shell */
   rb_define_attr(cUser, "shell", 1, 1);

   /* A comment field. Rarely used. */
   rb_define_attr(cUser, "gecos", 1, 1);

   /* The user's alloted amount of disk space */
   rb_define_attr(cUser, "quota", 1, 1);

   /* Used in the past for password aging. Deprecated in favor of /etc/shadow */
   rb_define_attr(cUser, "age", 1, 1);

   /* The user's access class */
   rb_define_attr(cUser, "access_class", 1, 1);

   /* Another comment field. Rarely used. */
   rb_define_attr(cUser, "comment", 1, 1);

   /* Account expiration date */
   rb_define_attr(cUser, "expire", 1, 1);

   /* Next date a password change will be needed */
   rb_define_attr(cUser, "change", 1, 1);

   /* The last time the user logged in */
   rb_define_attr(cUser, "login_time", 1, 0);

   /* The name of the terminal device the user last logged on with */
   rb_define_attr(cUser, "login_device", 1, 0);

   /* The hostname from which the user last logged in */
   rb_define_attr(cUser, "login_host", 1, 0);

   /* Group Attributes */

   /* The name of the group */
   rb_define_attr(cGroup, "name", 1, 1);

   /* The group's group ID */
   rb_define_attr(cGroup, "gid", 1, 1);

   /* An array of users that are members of the group */
   rb_define_attr(cGroup, "members", 1, 1);

   /* The group password, if any. */
   rb_define_attr(cGroup, "passwd", 1, 1);

   /* Constants */

   /* 1.5.2: The version of this library */
   rb_define_const(cAdmin, "VERSION", rb_str_new2(SYS_ADMIN_VERSION));
}
