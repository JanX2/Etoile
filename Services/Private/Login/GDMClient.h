#import <Foundation/Foundation.h>
#import "NSFileHandle+line.h"
#import "opcodes.h"

@interface GDMClient : NSObject
{
	NSFileHandle* input;
	NSFileHandle* output;
	NSString* desktop;
	NSString* user;
	NSString* password;
	NSMutableString* log;
	id delegate;
	BOOL waitForInput;
	BOOL loggingIn;
	NSString* lastLine;
}
- (void) setDelegate: (id) aDelegate;
- (id) initWithInput: (NSFileHandle*) input andOutput: (NSFileHandle*) output;
- (BOOL) logUser: (NSString*) anUser withPassword: (NSString*) aPassword;
- (void) setDesktop: (NSString*) aDesktop;
- (void) setUser: (NSString*) anUser;
- (void) setPassword: (NSString*) aPassword;
- (BOOL) parse;
- (void) beginning;
@end
