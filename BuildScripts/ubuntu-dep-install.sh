# Install Etoile and GNUstep dependencies for Ubuntu 9.04 (copied from INSTALL.Ubuntu)
# Universe repository needs to be enabled in /etc/apt/sources.list for libonig-dev to show up

sudo aptitude install gobjc-4.3 libxml2-dev libxslt1-dev libffi-dev libssl-dev libjpeg62-dev libtiff4-dev libpng12-dev libgif-dev libfreetype6-dev libx11-dev libcairo2-dev libxft-dev libxmu-dev dbus libdbus-1-dev hal libstartup-notification0-dev libxcursor-dev libxss-dev xscreensaver g++ libpoppler-dev libonig-dev  lemon libgmp3-dev postgresql libpq-dev libavcodec-dev libavformat-dev libtagc0-dev libmp4v2-dev

# Install Subversion to be able to check out Etoile

sudo aptitude install subversion
