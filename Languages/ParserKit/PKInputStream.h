#import <Foundation/Foundation.h>
@interface PKInputStream : NSObject
{
	@private
	NSMutableDictionary *memo;
	id stream;
	NSNumber position;
	NSMutableArray positionStack;
	id environmentStack;
}

- (id)initWithStream: (NSString*)stream;
- (NSNumber*)length;
- (id)stream;
- (id)substreamWithRange: (NSRange)range;
- (id)emptyStream;
@end
