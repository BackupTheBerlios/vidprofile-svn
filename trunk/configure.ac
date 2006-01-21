# Process this file with autoconf to produce a configure script.

# Copyright (C) 2005 Joe Friedrichsen <friedrij@users.berlios.de>
# 
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation; either 
# version 2 of the License, or (at your option) any later 
# version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# ******************************************************************************
# ******************************************************************************
#
#
# INIT
#
#
# ******************************************************************************
# ******************************************************************************

# The first arugment sets the package name, the second sets the package version.
# eg [vidprofile], [0.80] would yield a vidprofile-0.80.tar.gz after "$ make dist"
#                         the version number is also substituted into 
#                         lib-vidprofile.sh.in
AC_INIT([vidprofile], [svn])
AC_CONFIG_SRCDIR([src/profile.sh])

AM_INIT_AUTOMAKE




# ******************************************************************************
# ******************************************************************************
#
#
# CHECK FOR DEPENDENCIES 
#
#
# ******************************************************************************
# ******************************************************************************

# AC_MSG_CHECKING(feature-description)
# AC_MSG_RESULT(result-description)
# AC_PATH_PROG(variable, prog-to-check-for, [value-if-not-found])
# AC_CHECK_PROG(variable, prog-to-check-for, value-if-found, 
#               [value-if-not-found], [path-to-search], [reject])
# AC_MSG_WARN([problem-description])

# ******************************************************************************
# Required Dependencies 
# ******************************************************************************

AC_MSG_NOTICE([Checking for required dependencies...])
AC_CHECK_PROG(GREP, [grep], [ok], [MISSING])
AC_CHECK_PROG(MPLAYER, [mplayer], [ok], [MISSING])
AC_CHECK_PROG(MPEG2ENC, [mpeg2enc], [ok], [MISSING])
AC_CHECK_PROG(BC, [bc], [ok], [MISSING])

# ------------------------------------------------------------------------------
# Complain about missing required dependencies. If some are missing, list all
# missing ones before failing and exiting.

grep_msg="a GNU utility (http://www.gnu.org/software/grep)"
mplayer_msg="part of mplayer (http://www.mplayerhq.hu)"
mpeg2enc_msg="part of mjpegtools (http://mjpeg.sf.net}"
bc_msg="a GNU utility (http://directory.fsf.org/GNU/bc.html)"

# Sneaky make-do array. 
REQ_DEP_LIST="grep=$GREP mplayer=$MPLAYER mpeg2enc=$MPEG2ENC bc=$BC"

# We can use gawk with confidence because the above
# initiation macros look for it and will exit if gawk isn't found.
FAIL=false
for DEP in $REQ_DEP_LIST; do
   NAME=`echo $DEP | gawk -F '=' '{ print $1 }'`
   FOUND=`echo $DEP | gawk -F '=' '{ print $2 }'`
   if test "x$FOUND" = "xMISSING"; then
     FAIL=:
     ERR_MSG=$`eval echo ${NAME}_msg`
     ERR_MSG=`eval echo $ERR_MSG`
     MISSING_DEPS=`echo "$MISSING_DEPS"; printf "    %-9s %s\n" "$NAME" "$ERR_MSG"`
   fi
done

if $FAIL; then
 AC_MSG_ERROR([

  Could not find these REQUIRED dependencies:
$MISSING_DEPS
 
  Please install the missing dependencies and ./configure again.
])
fi


# ******************************************************************************
# Optional Dependencies 
# ******************************************************************************

AC_MSG_NOTICE([Checking for optional dependencies...])

# ------------------------------------------------------------------------------
# Disabled messages given to user in the FINAL SUMMARY when a dependency cannot
# be found.
pnmpsnr_msg="(cannot measure PSNR)"

# ------------------------------------------------------------------------------
# Check for Peak Signal to Noise Ratio dependencies
AC_CHECK_PROG(PNMPSNR, [pnmpsnr], [ok], [MISSING])

if test "x$PNMPSNR" = "xok"; then
   HAVE_PSNR="pnmpsnr"
else
   HAVE_PSNR=""
   AC_MSG_WARN([Cannot find pnmpsnr! You cannot measure PSNR.])
fi

# ------------------------------------------------------------------------------
# Clear the disabled messages if the corresponding dependencies were found.

# Sneaky make-do array. 
OPT_DEP_LIST="pnmpsnr=$PNMPSNR"

for DEP in $OPT_DEP_LIST; do
   NAME=`echo $DEP | gawk -F '=' '{ print $1 }'`
   FOUND=`echo $DEP | gawk -F '=' '{ print $2 }'`
   if test "x$FOUND" = "xok"; then
     unset ${NAME}_msg
   fi
done

if test "x$HAVE_PSNR" = "xpnmpsnr"
then
   OPT_DEPENDENCIES="ALL FOUND"
   OPT_DEP_MSG="SUCCESS!!"
   INSTALL_MSG="Type 'su -c \"make install\"' to compile and install vidprofile."
else
   OPT_DEPENDENCIES="SOME MISSING"
   OPT_DEP_MSG="PARTIAL PASS (the MISSING dependencies above are not supported)"
   INSTALL_MSG="Type 'su -c \"make install\"' to compile and install vidprofile anyway."
fi

# ******************************************************************************
# Build Options List, and make .in file substitutions
# ******************************************************************************

BUILD_OPTS=""
for OPT in $HAVE_PSNR
do
  if test -z $OPT; then :
  else
     BUILD_OPTS=" $OPT$BUILD_OPTS"
  fi
done
BUILD_OPTS="core$BUILD_OPTS"

# AC_SUBST(VARIABLE, [VALUE]) 
# Make VARIABLE .in file substitutable. @VARIABLE@ found inside .in files will 
# be replaced with VALUE
AC_SUBST(BUILD_OPTS)

AC_CONFIG_FILES([Makefile src/Makefile doc/Makefile src/lib-vidprofile.sh])
AC_OUTPUT

# ******************************************************************************
# ******************************************************************************
#
# PRETTY SUMMARY
#
# ******************************************************************************
# ******************************************************************************

AC_MSG_NOTICE([

FINAL SUMMARY

  Required dependencies: ALL FOUND

  Optional dependencies: $OPT_DEPENDENCIES
    pnmpsnr:       $PNMPSNR $pnmpsnr_msg

$OPT_DEP_MSG
  $INSTALL_MSG
])