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
    src/lib-vidprofile \
    src/profile \
    src/psnrcore \
    src/vidpsnr

man1_MANS = \
    doc/profile.man \
    doc/psnrcore.man \
    doc/vidpsnr.man
    
EXTRA_DIST = \
    $(bin_SCRIPTS) \
    $(man1_MANS)

# src/lib-vidprofile not needed b/c ./configure derives it from src/lib-vidprofile.in
dist-hook:
	rm -rvf $(top_distdir)/src/lib-vidprofile
