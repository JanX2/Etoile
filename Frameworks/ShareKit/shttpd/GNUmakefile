include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = SHTTPD

SHTTPD_C_FILES = \
	auth.c \
	cgi.c \
	compat_unix.c \
	config.c \
	io_cgi.c \
	io_dir.c \
	io_emb.c \
	io_file.c \
	io_socket.c \
	io_ssi.c \
	io_ssl.c \
	log.c \
	md5.c \
	mime_type.c \
	shttpd.c \
	string.c

#SHTTPD_OBJ_FILES = $(wildcard *.o)

ADDITIONAL_CFLAGS = -DEMBEDDED -DNO_CGI -DNO_SSI # -D_DEBUG

include $(GNUSTEP_MAKEFILES)/subproject.make

