#import "ETSerializer.h"
#import "ETSerializerBackend.h"
#import "ETDeserializer.h"

/**
 * Category for correctly serializing url objects.
 */
@implementation NSURL (ETSerializable)

- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	if(strcmp(aVariable, "_data") == 0 || strcmp(aVariable, "_clients") == 0)
	{
		return YES;
	}

	return [super serialize:aVariable using:aSerializer];
}

- (void) finishedDeserializing
{
	[self initWithString: _urlString relativeToURL: _baseURL];
}

@end
