#import <Foundation/Foundation.h>
#import "NSFileHandle+line.h"
#import "opcodes.h"

@interface GDMClient : NSObject
{
	NSFileHandle* input;
	NSFileHandle* output;
	NSString* desktop;
	NSMutableString* log;
	id delegate;
	BOOL waitForInput;
	BOOL loggingIn;
	NSString* lastLine;

	NSString *user;
	NSString *password;
}
- (void) setDelegate: (id) aDelegate;
- (id) initWithInput: (NSFileHandle*) input andOutput: (NSFileHandle*) output;
- (BOOL) loginWithUsername: (NSString*) userName 
                  password: (NSString*) password
                   session: (NSString *) session;
- (void) setDesktop: (NSString*) aDesktop;
- (void) parse;
- (void) beginning;
- (BOOL) read: (int) code;
@end

@interface NSObject (GDMClient)
- (void) gdmError: (id) sender;
- (void) gdmLogged: (id) sender;
@end
