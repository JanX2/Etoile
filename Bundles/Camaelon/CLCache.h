#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>

#ifndef __CLCache_H__
#define __CLCache_H__

@interface CLCache : NSObject
{
	NSMutableDictionary* cache;
}
+ (CLCache*) cache;
- (NSImage*) imageNamed: (NSString*) name;
- (void) setImage: (NSImage*) image named: (NSString*) name;
@end

#endif // __CLCache_H__
