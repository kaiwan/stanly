#!/bin/bash
# stanly.sh
# Static Analysis
#
# Quick Description:
# 
# Ref: https://elinux.org/images/d/d3/Bargmann.pdf
# 
# Last Updated :
# Created      :
# 
# Author:
# Kaiwan N Billimoria
# kaiwan -at- kaiwantech -dot- com
# 
# License: MIT.
# 
name=$(basename $0)
PFX=$(dirname `which $0`)
source ${PFX}/common.sh || {
 echo "${name}: fatal: could not source ${PFX}/common.sh , aborting..."
 exit 1
}

########### Globals follow #########################
# Style: gNameOfGlobalVar

# UPDATE on your box!
#gSRC=~/booksrc_LKDC/           # path to your codebase
gKSRC=~/kernel/linux-4.19.4    # kernel source tree root

########### Functions follow #######################

Warn()
{
  echo "$@"
}

mkclean()
{
  [ "$1" != "-q" ] && aecho "make clean"
  make clean >/dev/null || Warn "*** $(pwd) : 'make clean' failed"
}

sparse_check()
{
  wecho "sparse :"
  make C=1 CHECK="$(which sparse)" || Warn "*** $(pwd) : 'sparse' failed"
}

gccwarn1_check()
{
  mkclean -q
  wecho "gcc : make W=1 ['generally useful warnings']"
  make W=1 || Warn "*** $(pwd) : 'make W=1' failed"
}

gccwarn12_check()
{
  mkclean -q
  # usually overkill
  wecho "gcc : make W=12 ['possibly useful warnings']"
  make W=12 || Warn "*** $(pwd) : 'make W=12' failed"
}

clang_check()
{
  mkclean -q
  wecho "clang : make -skj20 CC=$(which clang)"
  make -skj20 CC=$(which clang) || Warn "*** $(pwd) : 'clang_check' failed"
}

coccinelle_check()
{
  mkclean -q
  ${gTOOLS}/coccichk .
  #wecho "coccinelle : make C=1 CHECK=${gKSRC}/scripts/coccicheck)"
  #make C=1 CHECK=${gKSRC}/scripts/coccicheck || Warn "*** $(pwd) : 'coccinelle_check' failed"
}


check_folder()
{
  # in a sub-shell
  (   
  cd $1
  techo "$(pwd)"

  sparse_check
  echo
  gccwarn1_check
  #echo
  #gccwarn12_check   # overkill
  echo
  clang_check
  echo
  coccinelle_check
  )
}

start()
{
gSRC=$1
gTOOLS=${gSRC}/tools

IFS=$'\n'; set -f
for d in $(find ${gSRC} -type d \
 -not -path "*.git*" -not -path "*.tmp_versions" -not -path "*tools")
do
  #echo "In $d:"
  [ ! -f $d/Makefile ] && continue
  becho "------------------------------------------------"
  check_folder $d
  echo
done

unset IFS; set +f
}

tools_check()
{
 which sparse >/dev/null || {
   echo "${name}: sparse missing, pl install"
   exit 1
 }
 [ ! -f ${gTOOLS}/coccichk ] && {
   echo "${name}: coccichk helper script missing"
   exit 1
 }
}


##### 'main' : execution starts here #####

[ $# -ne 1 ] && {
  echo "Usage: ${name} path-to-codebase-to-check"
  exit 1
}
[ ! -d $1 ] && {
  echo "${name}: path-to-codebase-to-check \"$1\" invalid?"
  exit 1
}

tools_check
start $1

exit 0
