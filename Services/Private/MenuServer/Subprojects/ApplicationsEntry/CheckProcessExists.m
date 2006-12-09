
#import "CheckProcessExists.h"

#import <Foundation/NSFileManager.h>
#import <Foundation/NSString.h>

#ifdef LINUX
#define HAVE_CHECK_PROCESS_EXISTS
BOOL
CheckProcessExists (int pid)
{
  return [[NSFileManager defaultManager]
    fileExistsAtPath: [NSString stringWithFormat: @"/proc/%i", pid]];
}
#endif

// default definition if no native implementation is available
#ifndef HAVE_CHECK_PROCESS_EXISTS
BOOL
CheckProcessExists (int pid)
{
  return NO;
}
#endif
