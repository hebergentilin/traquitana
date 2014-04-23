#
# Show a message
# msg(message, verbose, newline)
#
function msg() {
   local str="$1"

   echo "$str" >> $logfile
   echo -e "$str"
}

#
# Show usage
#
function usage() {
   echo "Usage:"
   echo ""
   echo "proc.sh <traq directory> <id> <verbose>"
   echo ""
   echo "-h Show this message"
   echo "-o Show gem dir owner"
   echo "-r Show gem dir owner, asking RVM"
   echo "-g Show gem dir owner, asking Rubygems"
   echo "-k Show Gemfile checksum"
   echo "-i Show gems provider (Rubygems, RVM, etc)"
   echo "-d Show gems dir"
}

#
# Gem dir
#
function gem_dir() {
   local provider=$(gem_provider)
   if [ -z "${provider}" ]; then
      echo ""
   else
      echo $(${provider}_gemdir)
   fi
}

# 
# RVM gem dir
#
function rvm_gemdir() {
   echo $(rvm gemdir)
}

#
# Rubygems gem dir
#
function rubygems_gemdir() {
   echo $(gem environment | grep INSTALLATION | cut -f2- -d:)
}

#
# Return the RVM gems dir owner
#
function rvm_owner() {
   echo $(stat --printf=%U $(rvm_gemdir))
}

#
# Return the gems dir owner
#
function rubygems_owner() {
   echo $(stat --printf=%U $(rubygems_gemdir))
}

# 
# Gems provider
#
function gem_provider() {
   if [ -n "$(which rvm)" ]; then
      echo "rvm"
   elif [ -n "$(which gem)" ]; then 
      echo "rubygems"
   else
      echo ""
   fi
}

#
# Find the current gem owner
# If not using RVM, returns the owner of the gem directory
#
function gemdir_owner() {
   local provider=$(gem_provider)
   if [ -z "${provider}" ]; then
      echo $(whoami)
   else
      echo $(${provider}_owner)
   fi
}

#
# Gemfile checksum
#
function gemfile_checksum() {
   echo $(md5sum Gemfile 2> /dev/null | cut -f1 -d' ')
}

#
# Move to the app directory
#
function cd_app_dir() {
   msg "Moving to ${dir} directory ..."
   cd $1/..
}

#
# Make a copy of the old contents
#
function safe_copy() {
   msg "Making a safety copy of the old contents on traq/$1.safe.zip ... "
   zip -q traq/$1.safe.zip `cat traq/$1.list` &> /dev/null
}

#
# Install the new files
#
function install_new_files() {
   msg "Unzipping $1.zip ... "
   unzip -o traq/$1.zip &> /dev/null
}

# 
# Create database if needed
#
function createdb() {
  msg "Creating database if needed ..."
  bundle exec rake db:create &> /dev/null
}

#
# Run migrations if needed
#
function migrate() {
   migrations=$(grep "^db/migrate" traq/${config_id}.list)
   if [ -n "$migrations" ]; then
      msg "Running migrations ... "
      bundle exec rake db:migrate 2> /dev/null
   fi
}

#
# Precompile assets if needed
#
function assets() {
   if [ -d app/assets ]; then
      msg "Compiling assets ... "
      bundle exec rake assets:precompile 2> /dev/null
   fi
}

#
# Change file permissions on public dir
#
function permissions() {
   if [ -d public ]; then
      msg "Changing file permissions on public to 0755 ... "
      chmod -R 0755 public/*
   fi
}

#
# Fix current gems, running bundle
#
function fix_gems() {
   msg "Fixing gems ..."
   local basedir=$(gem_dir | cut -f1-3 -d/)
   local owner=$(gemdir_owner)
   local curdir=$(pwd)
   local curuser=$(whoami)
   msg "Gem dir owner is \e[1m${owner}\e[0m"

   # if gemdir owner is root, try to install gems system wide
   if [ "${owner}" == "root" ]; then
      msg "Performing a \e[1msystem wide gem install\e[0m"
      # if current user is root, go on
      if [ "${curuser}" == "root" ]; then
         msg "Installing as \e[1mroot\e[0m"
         bundle install
      else
         msg "Installing with \e[1msudo\e[0m"
         sudo bash -l -c bundle install "${curdir}/Gemfile"
      fi
   # install gems on rvm system path or vendor/bundle
   else
      # if gemdir is the current user dir, install there
      if [ "${basedir}" == "/home/${owner}" ]; then
         msg "Performing a \e[1mlocal gem install on home dir\e[0m"
         bundle install
      # if user is not root and gemdir is not the home dir, install on vendor
      else
         msg "Performing a \e[1mlocal gem install on vendor/bundle\e[0m"
         bundle install --path vendor/bundle
      fi
   fi
}

# force the production enviroment
export RAILS_ENV=production

config_dir="$1"            # config dir
config_id="$2"             # config id
verbose="$3"               # verbose mode
newline="true"             # default newline on messages
logfile="/tmp/traq$$.log"  # log file

# parse command line options
while getopts "horgkid" OPTION
do
   case ${OPTION} in
      h)
         usage
         exit 1
         ;;
      o)
         echo "Gem dir owner is: $(gemdir_owner)"
         exit 1
         ;;
      r)
         echo "RVM gem dir owner is: $(rvm_owner)"
         exit 1
         ;;
      g)
         echo "Ruby gems dir owner is: $(rubygems_owner)"
         exit 1
         ;;
      k)
         echo "Gemfile checksum is: $(gemfile_checksum)"
         exit 1
         ;;
      i)
         echo "Gems provider is $(gem_provider)"
         exit 1
         ;;
      d)
         echo "Gems dir is $(gem_dir)"
         exit 1
         ;;
      *) 
         usage 
         exit 1
         ;;
   esac
done

msg "Log file is ${logfile}"

# move to the correct directory
dir="${1}"
cd_app_dir "${dir}"
safe_copy "${config_id}"

# check Gemfile checksum
old_gemfile_md5=$(gemfile_checksum)
install_new_files "${config_id}"
new_gemfile_md5=$(gemfile_checksum)

# if the current Gemfile is different, run bundle install
if [ -f Gemfile -a "$old_gemfile_md5" != "$new_gemfile_md5" ]; then
   fix_gems
fi

createdb
migrate
assets
permissions

# restart server
if [ -x ./traq/server.sh -a -f ./traq/server.sh ]; then
   ./traq/server.sh
fi

# extra configs
if [ -x ./traq/extra.sh -a -f ./traq/extra.sh ]; then
   ./traq/extra.sh
fi

# erase file
rm traq/${config_id}.zip
