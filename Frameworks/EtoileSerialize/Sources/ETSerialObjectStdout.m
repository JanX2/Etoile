#import "ETObjectStore.h"

@implementation ETSerialObjectStdout 
- (void) commit 
{
	fwrite([buffer bytes], [buffer length], 1, stdout);
}
@end
