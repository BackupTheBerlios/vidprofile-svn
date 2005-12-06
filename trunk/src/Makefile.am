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

bin_SCRIPTS = \
    lib-vidprofile \
    profile \
    psnrcore \
    vidpsnr

CLEANFILES = $(bin_SCRIPTS)

EXTRA_DIST = \
    lib-vidprofile.sh.in \
    profile.sh \
    psnrcore.sh \
    vidpsnr.sh

lib-vidprofile: $(srcdir)/lib-vidprofile.sh
	rm -f "lib-vidprofile"
	echo "#! `which env` sh"  > lib-vidprofile
	cat $(srcdir)/lib-vidprofile.sh >> lib-vidprofile
	chmod ugo+x lib-vidprofile

profile: $(srcdir)/profile.sh
	rm -f "profile"
	echo "#! `which env` sh"  > profile
	cat $(srcdir)/profile.sh >> profile
	chmod ugo+x profile

psnrcore: $(srcdir)/psnrcore.sh
	rm -f "psnrcore"
	echo "#! `which env` sh"  > psnrcore
	cat $(srcdir)/psnrcore.sh >> psnrcore
	chmod ugo+x psnrcore

vidpsnr: $(srcdir)/vidpsnr.sh
	rm -f "vidpsnr"
	echo "#! `which env` sh"  > vidpsnr
	cat $(srcdir)/vidpsnr.sh >> vidpsnr
	chmod ugo+x vidpsnr