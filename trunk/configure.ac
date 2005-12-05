# Process this file with autoconf to produce a configure script.

# Copyright (C) 2005 Joe Friedrichsen <pengi.films@gmail.com>
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

AC_INIT([vidprofile], [0.8])
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
AC_PATH_PROG(GREP, [grep], [NOT FOUND])
AC_PATH_PROG(MPLAYER, [mplayer], [NOT FOUND])
AC_PATH_PROG(MPEG2ENC, [mpeg2enc], [NOT FOUND])
AC_PATH_PROG(BC, [bc], [NOT FOUND])

if test "$GREP" = "NOT FOUND" || \
   test "$MPLAYER" =  "NOT FOUND" || \
   test "$MPEG2ENC" =  "NOT FOUND" || \
   test "$BC" = "NOT FOUND"; then
        AC_MSG_ERROR([ Could not find these REQUIRED dependencies:

    grep:               $GREP
    mplayer:            $MPLAYER
    mpeg2enc:           $MPEG2ENC
    bc:                 $BC
])
fi

# ******************************************************************************
# Optional Dependencies 
# ******************************************************************************

AC_MSG_NOTICE([Checking for optional dependencies...])
AC_CHECK_PROG(HAVE_PNMPSNR, [pnmpsnr], [pnmpsnr], [no-pnmpsnr])

if test "$PNMPSNR" = "no-pnmpsnr"; then
        AC_MSG_WARN([Could not find these OPTIONAL dependencies:
    pnmpsnr:            $HAVE_PNMPSNR
])
fi

# ******************************************************************************
# ******************************************************************************
#
# PRETTY SUMMARY
#
# ******************************************************************************
# ******************************************************************************

AC_MSG_NOTICE([

FINAL SUMMARY

  Required dependencies
    grep:               $GREP
    mplayer:            $MPLAYER
    mpeg2enc:           $MPEG2ENC
    bc:                 $BC

  Optional dependencies
    pnmpsnr:            $HAVE_PNMPSNR
])

AC_CONFIG_FILES([Makefile src/Makefile doc/Makefile src/lib-vidprofile.sh])
AC_OUTPUT