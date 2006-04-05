#ifndef ob__version_h
#define ob__version_h

#define OB_MAJOR_VERSION 3
#define OB_MINOR_VERSION 3
#define OB_MICRO_VERSION 3
#define OB_VERSION OB_MAJOR_VERSION.OB_MINOR_VERSION.OB_MICRO_VERSION

#define OB_CHECK_VERSION(major,minor,micro) \
    (OB_MAJOR_VERSION > (major) || \
     (OB_MAJOR_VERSION == (major) && OB_MINOR_VERSION > (minor)) || \
     (OB_MAJOR_VERSION == (major) && OB_MINOR_VERSION == (minor) && \
      OB_MICRO_VERSION >= (micro)))

#endif
