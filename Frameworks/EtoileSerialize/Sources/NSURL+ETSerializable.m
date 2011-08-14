#define EXPOSE_NSURL_IVARS
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
	[_baseURL finishedDeserializing];
	[self initWithString: _urlString relativeToURL: _baseURL];
}

@end
