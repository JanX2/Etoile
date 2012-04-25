#import <Foundation/Foundation.h>
@interface PKParseMatch : NSObject
{
	@private
	id input;
	NSValue *range;
	id action;
	id delegate;
}

- (void)setDelegate: (id)delegate;
- (BOOL)isSuccess;
- (BOOL)isFailure;
- (id)matchText;
- (NSValue*)range;
- (id)reduce;
@end

@interface PKParseFail : NSObject
{
	@private

	id input;
	id failedPosition;
	id describ;
	id delegate;
	PKParseFail *cause;
}

- (void)setDelegate: (id)delegate;
- (BOOL)isSuccess;
- (BOOL)isFailure;
- (NSNumber*)stopPosition;
- (PKParseFail*)cause;
@end
