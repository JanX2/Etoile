#import "ETObjectStore.h"

@implementation ETSerialObjectStdout 
- (void) finalize 
{
	fwrite([buffer bytes], [buffer length], 1, stdout);
}
@end
