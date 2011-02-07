#include "GraphWriter.h"

@implementation GraphWriter

- (id) init
{
	self = [super init];
	mNodes = [NSMutableDictionary new];
	mEdges = [NSMutableArray new];
	mGraphContext = gvContext();
	mGraph = agopen("g", AGDIGRAPH);
	return self;
}

- (void) dealloc
{
        [self cleanupGraph];
	[mEdges release];
	[mNodes release];
	[super dealloc];
}

- (void) cleanupGraph
{
	gvFreeLayout(mGraphContext, mGraph);
	agclose(mGraph);
	gvFreeContext(mGraphContext);
}

- (void) generateImageFile: (NSString*) path
{
	gvLayout(mGraphContext, mGraph, "dot");
	gvRenderFilename(mGraphContext, mGraph, "png", (char*) [path cString]);
}

- (NSValue*) addNode: (NSString*) node
{
	NSValue* pointer = [mNodes objectForKey: node];
	if (pointer)
		return pointer;

	Agnode_t *n = agnode(mGraph, (char*)[node cString]);
	NSValue* value = [NSValue valueWithPointer: n];
	[mNodes setObject: value forKey: node];
	return value;
}

- (void) addEdge: (NSString*) nodeA to: (NSString*) nodeB
{
	NSValue* A = [self addNode: nodeA];
	NSValue* B = [self addNode: nodeB];
	agedge(mGraph, [A pointerValue], [B pointerValue]);
}
	
@end
