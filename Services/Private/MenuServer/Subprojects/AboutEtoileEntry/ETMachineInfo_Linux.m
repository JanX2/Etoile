/*
    ETMachineInfo_Linux.m

    Linux specific backend for ETMachineInfo.

    Copyright (C) 2005, 2006  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#ifdef LINUX

#import "ETMachineInfo.h"
#import <sys/types.h>
#import <sys/stat.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSString.h>

static inline int
my_round (float x)
{
  return (int) (x + 0.5);
}

@implementation ETMachineInfo (Linux)

+ (unsigned long long) realMemory
{
  // The size of /proc/kcore on Linux gives the total memory
  return [[[NSFileManager defaultManager]
    fileAttributesAtPath: @"/proc/kcore" traverseLink: YES]
    fileSize];
}

+ (unsigned int) cpuMHzSpeed
{
  // read /proc/cpuinfo for the processor type
  NSEnumerator * e = [[[NSString stringWithContentsOfFile: @"/proc/cpuinfo"]
    componentsSeparatedByString: @"\n"]
    objectEnumerator];
  NSString * line;

  while ((line = [e nextObject]) != nil)
    {
      if ([line hasPrefix: @"cpu MHz"])
        {
           NSArray * comps = [line componentsSeparatedByString: @":"];

           if ([comps count] > 1)
             {
               return my_round ([[comps objectAtIndex: 1] floatValue]);
             }
        }
	  /* Different format for non-x86 platforms including PowerPC */
	  else if ([line hasPrefix: @"clock"])
	  {
           NSArray * comps = [line componentsSeparatedByString: @":"];

           if ([comps count] > 1)
             {
				NSString * speed = [comps objectAtIndex: 1];
				float mhz = my_round ([speed floatValue]);
				/* Assume MHz unless GHz found */
				NSRange * suffix = [speed rangeOfString:@"ghz" options:NSCaseInsensitiveSearch];
				if(suffix.location != NSNotFound)
				{
					mhz *= 1024;
				}
				return mhz;
             }
	  }
    }

  return 0;
}

+ (NSString *) cpuName
{
  // read /proc/cpuinfo for the processor type
  NSEnumerator * e = [[[NSString stringWithContentsOfFile: @"/proc/cpuinfo"]
    componentsSeparatedByString: @"\n"]
    objectEnumerator];
  NSString * line;

  while ((line = [e nextObject]) != nil)
    {
      if ([line hasPrefix: @"model name"])
        {
          NSArray * comps = [line componentsSeparatedByString: @":"];

          if ([comps count] > 1)
            {
              return [[comps objectAtIndex: 1] stringByTrimmingSpaces];
            }
        }
    }

  return nil;
}

+ (BOOL) platformSupported
{
  return YES;
}

@end

#endif // LINUX
