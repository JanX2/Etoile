
#import <Foundation/NSObject.h>

@interface MenuletLoader : NSObject
{
  NSArray * menulets;
}

+ shared;

- (void) loadMenulets;

@end
