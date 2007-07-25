#!/bin/sh

# --shrink

echo
echo "Entering Shrink stage..."

# Try to clean up as much GNOME stuff as possible

# NOTE: Trick to enable universe repository install deborphan that allows to purge which got removed without --purge
#cp /etc/apt/sources.list /etc/apt/sources.list.backup
#sudo sed -i -e "s/# deb/deb/g" /etc/apt/sources.list

# NOTE: 'dpkg -l' reports them but 'apt-get remove' cannot find them
# app-install-data* before-light

# FIXME: compiz* removes too many stuff like objc compiler
# fstobdf
# ^gconf* removes gdm
# ^gij* matches way too many things
# ^gnome* removes gdm
# ^languages-pack-gnome-*
# ^libdb4*
# ^libgcj*
# ^libgconf* ^libgda*
# ^libgdbm* ^libgdi* 
# ^libmagick*
# ^libnewt*
# ^liborbit* removes gconf
# ^libpango* removes gdm
# ^libpq* ^libpt* 
# ^libsasl* removes gconf and gdm
# ^libselinux* ^libpi* libtext-charwidth-perl libtext-wrapi18n-perl ^libxaw* removes xorg
# ^libslab* ^libslang* ^libslp* creates conflicts with ubiquity and/or font-config
# ^python* removes gdm and gconf and probably too many things
# gksu ^libgksu* ^libcroco* ^libglade*  ^libgnome* ^libgtop* removes gdm
#^libbrlapi* ^libatk1*
#^gtk2* ^libgtk*

# NOTE: Removing gnome-desktop-environment metapackage should be pretty good,
# I suppose it removes openoffice.org metapackage by the way.

apt-get remove alacarte apport-gtk at-spi ^brltty* bug-buddy capplets-data cli-common contact-lookup-applet deskbar-applet desktop-effects diveintopython docbook-xml ekiga eog evince ^evolution* f-spot file-roller ^gaim* gcalctool gcc-3.3-base ^gedit* gimp gparted gstreamer0.10-gnomevfs ^gtkhtml* ^guile* hwdb-client-gnome ^language-pack-* libapr1 ^libatspi* ^libaudio* ^libaudiofile* ^libbeagle* ^libbonobo* ^libcamel* ^libdjvulibre* ^libebook* ^libecal* ^libedata* ^libeel* ^libegroupwise* ^libexchange-storage* ^libgadu* ^libgail* ^libgamin* ^libgimp*  libglib-perl libglib2.0-cil libgmime2.2-cil  ^libgucharmap* ^libguile* libhsqldb-java ^libhtml* ^libjaxp* libjline-java ^liblaunchpad-integration* ^liblircclient* ^liblpint-bonobo* ^libmetacity* ^libmono* ^libnautilus* libnet-dbus-perl ^libnm-glib* ^libnspr* ^libopal*  ^libparted* ^libperl*  libpoppler1-glib ^libqthreads*  ^libscrollkeeper* ^libsdl* libservlet2.3-java ^libsexy* ^libsigc++* ^libsoup* ^libtotem-plparser* ^libuniconf* liburi-perl libvisual* ^libvte* ^libwmf* ^libwnck* ^libwpd8c2a ^libwps* ^libwvstreams* libwww-perl libxalan2-java  libxerces2-java libxml-parser-perl libxml-twig-perl ^libxplc* ^metacity* ^mono-* mscompress ^nautilus* ^network-manager* ^openoffice.org* rdesktop rhythmbox scim-gtk2-immodule scrollkeeper serpentine software-properties-gtk sound-juicer ssh-askpass-gnome thunderbird-locale-en-gb tomboy totem tsclient ^update-manager* update-notifier vino w3m yelp

deborphan | xargs apt-get remove --purge -y # deborphan --guess-all
dpkg --list | grep ^rc | awk '{print $2}'
... et pour les purger :
# COLUMNS=300 dpkg --list | grep ^rc | awk '{print $2}' | xargs dpkg -P

# To be sure no critical packages have been removed
apt-get -y install language-pack-en ssh firefox

# On firefox install at this point, apt-get reports:
#The following extra packages will be installed:
#  libhunspell-1.1-0 libnspr4 libnss3
#Suggested packages:
#  firefox-gnome-support latex-xft-fonts firefox-libthai
#The following NEW packages will be installed:
#  firefox libhunspell-1.1-0 libnspr4 libnss3
#
# On shh install:
#The following extra packages will be installed:
#  openssh-server
#Suggested packages:
#  ssh-askpass rssh molly-guard
#The following NEW packages will be installed:
#  openssh-server ssh

# NOTE: To avoid any warnings of this style after the removing of some packages
# reinstall language-pack-en
#XXX: warning: Setting locale failed.
#XXX: warning: Please check that your locale settings:
#       LANGUAGE = (unset),
#       LC_ALL = (unset),
#       LANG = "en_US.UTF-8"
#   are supported and installed on your system.
#XXX: warning: Falling back to the standard locale ("C").

# A last check to verify package tree integrity
apt-get check

exit

