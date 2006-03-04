
#import <Foundation/NSObject.h>

@protocol NSMenuItem;
@class NSString;

@protocol EtoileSystemBarEntry

- (id <NSMenuItem>) menuItem;

- (NSString *) menuGroup;

@end
