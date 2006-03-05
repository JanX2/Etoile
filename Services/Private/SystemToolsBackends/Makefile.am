SUBDIRS = m4macros files po

backends = \
	dhcpd-conf \
	disks-conf \
	memory-conf \
	network-conf \
	services-conf \
	shares-conf \
	time-conf \
	users-conf \
	boot-conf \
	print-conf \
	mouse-conf \
	internetsharing-conf \
	package-conf \
	display-conf \
	font-conf

perl_libs = \
	boot.pl      \
	boot-grub.pl \
	boot-lilo.pl \
	boot-yaboot.pl \
	dhcpd.pl     \
	debug.pl     \
	file.pl      \
	filesys.pl   \
	font.pl      \
	general.pl   \
	ishare.pl    \
	media.pl     \
	network.pl   \
	parse.pl     \
	partition.pl \
	platform.pl  \
	print.pl     \
	process.pl   \
	replace.pl   \
	report.pl    \
	service.pl   \
	service-list.pl	\
	share.pl     \
	tokenizer.pl \
	util.pl      \
	x.pl         \
	xml.pl

scripts_SCRIPTS = $(backends) $(perl_libs) guess_system.sh type1inst

EXTRA_DIST = \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	system-tools-backends.pc.in \
	guess_system.sh \
	type1inst       \
	README \
	AUTHORS \
	NEWS

CLEANFILES = $(backends) $(perl_libs)

DISTCLEANFILES =	\
	intltool-extract 	\
	intltool-merge		\
	intltool-update

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = system-tools-backends.pc
