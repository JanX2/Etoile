/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "ETUUID.h"
#import "EtoileCompatibility.h"
#include <stdlib.h>
// On *BSD and Linux we have a srandomdev() function which seeds the random 
// number generator with entropy collected from a variety of sources. On other
// platforms we don't, so we use some less random data based on the current 
// time and pid to seed the random number generator.
#if defined(__FreeBSD__) || defined(__OpenBSD) || defined(__DragonFly__)
#define INITRANDOM() srandomdev()
#elif defined(__linux__)
#include <time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
/** Returns a strong random number which can be used as a seed for srandom().
    This random number is obtained from Linux entropy pool through /dev/random.
    Unlike /dev/urandom, /dev/random blocks when the entropy estimate isn't 
    positive enough. In this case, a random number is created by falling back on 
    the following combination:
   'current time' + 'pid' + 'an uninitialized var value' 
    
    ETSRandomDev is derived from FreeBSD libc/stdlib/random.c srandomdev(). */
static void ETSRandomDev()
{
	int fd = -1;
	unsigned int seed = 0;
	size_t len = sizeof(seed);
	BOOL hasSeed = NO;

	fd = open("/dev/random", O_RDONLY | O_NONBLOCK, 0);
	if (fd >= 0) 
	{
		if (errno != EWOULDBLOCK)
		{
			if (read(fd, &seed, len) == (ssize_t)len)
			{
				hasSeed = YES;
			}
		}
		close(fd);
	}

	if (hasSeed == NO) 
	{
		struct timeval tv;
		unsigned long junk;
		
		gettimeofday(&tv, NULL);
		seed = ((getpid() << 16) ^ tv.tv_sec ^ tv.tv_usec ^ junk);
	}
	
	srandom(seed);
}
#define INITRANDOM() ETSRandomDev()
#else
static void ETSRandomDev()
{
	struct timeval tv;
	unsigned long junk;
	unsigned int seed = 0;

	/* Within a process, junk is always initialized to the same value (on Linux), 
	   gettimeofday is microsecond-based and pid is fixed. This leads to many 
	   collisions if you call ETSRandomDev() in a loop, as -testString does
	   in TestUUID.m. */

	gettimeofday(&tv, NULL);
	seed = ((getpid() << 16) ^ tv.tv_sec ^ tv.tv_usec ^ junk);
	//ETLog(@"seed %u --- sec %li usec %li junk %lu pid %u", seed, tv.tv_sec, tv.tv_usec, junk, getpid());

	srandom(seed);
}
#define INITRANDOM() ETSRandomDev()
#endif
#import "Macros.h"


#define TIME_LOW(uuid) (*(uint32_t*)(uuid))
#define TIME_MID(uuid) (*(uint16_t*)(&(uuid)[4]))
#define TIME_HI_AND_VERSION(uuid) (*(uint16_t*)(&(uuid)[6]))
#define CLOCK_SEQ_HI_AND_RESERVED(uuid) (*(&(uuid)[8]))
#define CLOCK_SEQ_LOW(uuid) (*(&(uuid)[9]))
#define NODE(uuid) ((char*)(&(uuid)[10]))

@implementation ETUUID
+ (void) initialize
{
	INITRANDOM();
}
+ (id) UUID
{
	return AUTORELEASE([[self alloc] init]);
}

- (id) init
{
	SUPERINIT

	// Initialise with random data.
	for (unsigned i=0 ; i<16 ; i++)
	{
		long r = random();
		uuid[i] = (unsigned char)r;
	}
	// Clear bits 6 and 7
	CLOCK_SEQ_HI_AND_RESERVED(uuid) &= (unsigned char)63;
	// Set bit 6
	CLOCK_SEQ_HI_AND_RESERVED(uuid) |= (unsigned char)64;
	// Clear the top 4 bits
	TIME_HI_AND_VERSION(uuid) &= 4095;
	// Set the top 4 bits to the version
	TIME_HI_AND_VERSION(uuid) |= 16384;
	return self;
}

- (id) initWithUUID: (unsigned char *)aUUID
{
	SUPERINIT

	memcpy(&uuid, aUUID, 16);

	return self;
}

- (id) initWithString: (NSString *)aString
{
	SUPERINIT

	const char *data = [aString UTF8String];
	sscanf(data, "%x-%hx-%hx-%2hhx%2hhx-%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx", 
	   &TIME_LOW(uuid), 
	   &TIME_MID(uuid),
	   &TIME_HI_AND_VERSION(uuid),
	   &CLOCK_SEQ_HI_AND_RESERVED(uuid),
	   &CLOCK_SEQ_LOW(uuid),
	   &NODE(uuid)[0],
	   &NODE(uuid)[1],
	   &NODE(uuid)[2],
	   &NODE(uuid)[3],
	   &NODE(uuid)[4],
	   &NODE(uuid)[5]);

	return self;
}

- (id) copyWithZone: (NSZone *)zone
{
	return RETAIN(self);
}

- (BOOL) isEqual: (id)anObject
{
	if (![anObject isKindOfClass: [self class]])
	{
		return NO;
	}
	const unsigned char *other_uuid = [anObject UUIDValue];
	for (unsigned i=0 ; i<16 ; i++)
	{
		if (uuid[i] != other_uuid[i])
		{
			return NO;
		}
	}
	return YES;
}

- (NSString *) stringValue
{
	return [NSString stringWithFormat:
		@"%0.2x-%0.2hx-%0.2hx-%0.2hhx%0.2hhx-%0.2hhx%0.2hhx%0.2hhx%0.2hhx%0.2hhx%0.2hhx", 
		   TIME_LOW(uuid), 
		   TIME_MID(uuid),
		   TIME_HI_AND_VERSION(uuid),
		   CLOCK_SEQ_HI_AND_RESERVED(uuid),
		   CLOCK_SEQ_LOW(uuid),
		   NODE(uuid)[0],
		   NODE(uuid)[1],
		   NODE(uuid)[2],
		   NODE(uuid)[3],
		   NODE(uuid)[4],
		   NODE(uuid)[5]];
}

- (const unsigned char *) UUIDValue
{
	return uuid;
}

- (NSString*) description
{
	return [self stringValue];
}
@end


@implementation NSString (ETUUID)

+ (NSString *) UUIDString
{
	ETUUID *uuid = [[ETUUID alloc] init];
	NSString *str = [uuid stringValue];

	RELEASE(uuid);
	return str;
}

@end
