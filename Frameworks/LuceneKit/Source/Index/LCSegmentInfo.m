#include <LuceneKit/Index/LCSegmentInfo.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCSegmentInfo

- (id) initWithName: (NSString *) n
  numberOfDocuments: (int) count
		  directory: (id <LCDirectory>) d
{
	self = [super init];
	ASSIGN(name, n);
	docCount = count;
	ASSIGN(dir, d);
	return self;
}

- (void) dealloc
{
	RELEASE(name);
	RELEASE(dir);
	[super dealloc];
}

- (NSString *) name
{
	return name;
}

- (int) numberOfDocuments
{
	return docCount;
}

- (id <LCDirectory>) directory
{
	return dir;
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"LCSegmentInfo: name %@, docCount %d", name, docCount];
}

@end
