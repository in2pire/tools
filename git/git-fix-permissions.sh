#!/bin/bash

################################################################################
# Copyright (c) 2014 IN2PIRE
################################################################################

me=`basename $0`
target=$1
working_path=$(pwd)
verbose=0

if [ ! -d $target ]; then
  echo -e "\033[31mTarget is not a directory: $target\033[0m"
  exit 1
fi

cd "$target" &>/dev/null
target=$(pwd)
cd "$working_path" &>/dev/null

if [ ! -d "$target/.git" ]; then
  echo -e "\033[31mTarget is not a git repository: $target\033[0m"
  exit 1
fi

# Add to hashmap
map_put() {
  alias "${1}$2"="$3"
}

# Get from hash map
map_get() {
  alias "${1}$2" | awk -F"'" '{ print $2; }'
}

# Delete from hash map
map_unset() {
  unalias "${1}$2"
}

# Check hashmap key
map_key_not_exists() {
  alias "${1}$2" &>/dev/null
}

# List all hashmap key
map_keys() {
  alias -p | grep $1 | cut -d'=' -f1 | awk -F"$1" '{print $2; }'
}

usage() {
  echo
  echo "usage: ./$me target"
  echo
  echo 'Options'
  echo "  target   Path to directory that you want to fix file permissions"
  echo
  echo 'More options'
  echo "  -v,  --verbose   Verbose mode"
  echo '  -h,  --help      Print this help'
  echo

  exit 1
}

fix_git_permissions() {
  cd "${1}" &>/dev/null
  git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' | git apply &>/dev/null
  cd -  &>/dev/null
}

args=("$@")

while getopts “a:n:p:c?:d?:h?:-:” OPTION
do
  case "$OPTION" in
    d | - )
    ;;
    h | *)
      usage
    ;;
  esac
done

for i in "${args[@]}";
do
  case $i in
    -a=*|--author=* )
      author="${i#*=}"
    ;;
    -n=*|--name=* )
      project="${i#*=}"
    ;;
    -p=*|--path=* )
      destination="${i#*=}"
    ;;
    -v|--verbose )
      verbose=1
    ;;
    -h|--help )
      # unknown option
      usage
    ;;
  esac
done

cd "$target"
submodules=$(git submodule status | cut -d' ' -f3)
num_submodules=$(echo "$submodules" | sed '/^\s*$/d' | wc -l)
cd "$working_path"

fix_git_permissions "$target"

if [ $verbose -ne 0 ]; then
  echo

  if [ $num_submodules -ne 0 ]; then
    echo -e "\033[4mMain repository\033[0m";
  fi

  echo -n $'🍺  '
  echo -e "\033[93mFix \033[0m$target"
fi

if [ $num_submodules -ne 0 ]; then
  if [ $verbose -ne 0 ]; then
    echo
    echo -e "\033[4mSubmodules\033[0m";
  fi

  cd "$target" &>/dev/null

  for submodule in $submodules
  do
    cd "$submodule" &>/dev/null
    submodule=$(pwd)
    cd - &>/dev/null
    fix_git_permissions "$submodule"

    if [ $verbose -ne 0 ]; then
      echo -n $'🍺  '
      echo -e "\033[93mFix \033[0m$submodule"
    fi
  done

  cd "$working_path" &>/dev/null
fi

echo
echo "done!"
echo
