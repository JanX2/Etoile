#import <Foundation/Foundation.h>
#import "COObject.h"

@interface COObject (Subclass)

+ (Class) autogeneratedSubclassForClass: (Class)cls entityDescription: (ETEntityDescription *)entity;

@end
