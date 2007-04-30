#import <Foundation/Foundation.h>

@interface NSFileHandle (line)

- (NSData*) readDataWithSize: (unsigned int) size;
- (void) writeLine: (NSString*) string;
- (NSString*) readLine;

- (void) sendSTX;
- (void) sendMSG: (NSString*) message;
- (void) waitUntilData: (id) log;

@end
