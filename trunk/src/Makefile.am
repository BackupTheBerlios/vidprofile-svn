# Process this file with automake to produce a Makefile.in

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

# List the source files for each shell script to be built and 
# installed. Correct names are automatically created for the 
# build process, as well as install directives.

sh_source = \
    lib-vidprofile.sh \
    profile.sh \
    psnrcore.sh \
    vidpsnr.sh

################### LEAVE BELOW ALONE #########################

# No need to modify anything below! The above list can 
# handle an arbitrary amount of shell scripts.
# Everything is correctly built, installed, and cleaned so long
# as the source files have a .sh suffix for shell scripts.

# Strip the source file extentions. A built file will be called
# by the basename of its source.
#   eg: profile.sh becomes made and installed as profile
sh_bin = $(basename $(sh_source))

# Specify the scripts to make and install.
bin_SCRIPTS = $(sh_bin)

# Clean the built scripts only. Leave the source files alone.
CLEANFILES = $(bin_SCRIPTS)

# Distribute the source files so the suite can be built!
EXTRA_DIST = $(sh_source)

# Make all the shell scripts.
# These are Static Pattern Rules, found at:
# http://www.gnu.org/software/make/manual/html_mono/make.html#SEC47
$(sh_bin): %: %.sh
	rm -f "$@"
	echo "#! `command -v sh`"  > $@
	cat $(srcdir)/$< >> $@
	chmod ugo+x $@
