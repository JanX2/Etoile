#include <stdio.h>
#include <unistd.h>
#include "DocGraphWriter.h"

@implementation DocGraphWriter

- (id) init
{
	self = [super init];
	mNodes = [NSMutableDictionary new];
	mEdges = [NSMutableArray new];
	mGraphContext = gvContext();
	mGraph = agopen("g", Agdirected, NULL);
	[self setGraphAttribute: @"rankdir" with: @"BT"];
	[self setGraphAttribute: @"size" with: @"2."];
	[self setGraphAttribute: @"dpi" with: @"72"];
	return self;
}

- (void) dealloc
{
	[self cleanupGraph];
}

- (void) cleanupGraph
{
	gvFreeLayout(mGraphContext, mGraph);
	agclose(mGraph);
	gvFreeContext(mGraphContext);
}

- (void) layout
{
	gvLayout(mGraphContext, mGraph, "dot");
}

- (void) generateFile: (NSString*) path withFormat: (NSString*) format
{
	gvRenderFilename(mGraphContext, mGraph,
		(char*) [format UTF8String], (char*) [path UTF8String]);
}

- (NSString*) generateWithFormat: (NSString*) format
{
	NSFileHandle* handle = [[NSFileManager defaultManager] tempFile];

	FILE* file = fdopen([handle fileDescriptor], "w+");
	gvRender(mGraphContext, mGraph,
		(char*) [format UTF8String], file);

	[handle seekToFileOffset: 0];
	NSData* data = [handle readDataToEndOfFile];
	NSString* str = [[NSString alloc] initWithData: data
				encoding: NSUTF8StringEncoding];

	return str;
}

- (NSValue*) addNode: (NSString*) node
{
	NSValue* pointer = [mNodes objectForKey: node];
	if (pointer)
		return pointer;

	Agnode_t *n = agnode(mGraph, (char*)[node UTF8String], 1);
	NSValue* value = [NSValue valueWithPointer: n];
	[mNodes setObject: value forKey: node];
	return value;
}

- (void) addEdge: (NSString*) nodeA to: (NSString*) nodeB
{
	NSValue* A = [self addNode: nodeA];
	NSValue* B = [self addNode: nodeB];
	agedge(mGraph, [A pointerValue], [B pointerValue], "", 1);
}

- (void) setAttribute: (NSString*) attribute
		 with: (NSString*) value
		   on: (NSString*) node
{
	NSValue* n = [self addNode: node];
	agsafeset([n pointerValue],
		 (char*) [attribute UTF8String],
		 (char*) [value UTF8String], "");
}

- (void) setGraphAttribute: (NSString*) attribute
	              with: (NSString*) value
{
	agsafeset(mGraph,
		 (char*) [attribute UTF8String],
		 (char*) [value UTF8String], "");
}

@end
