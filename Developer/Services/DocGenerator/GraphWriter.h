#import <Foundation/Foundation.h>
#include <graphviz/gvc.h>

@interface GraphWriter : NSObject
{
	NSMutableDictionary* mNodes;
	NSMutableArray* mEdges;
	Agraph_t *mGraph;
	GVC_t* mGraphContext;
}
- (void) cleanupGraph;
- (NSValue*) addNode: (NSString*) node;
- (void) addEdge: (NSString*) nodeA to: (NSString*) nodeB;
- (void) setAttribute: (NSString*) attribute
		 with: (NSString*) value
		   on: (NSString*) node;
- (void) setGraphAttribute: (NSString*) attribute
		      with: (NSString*) value;
- (void) layout;
/*
 * File formats: png, cmap for image maps
 */
- (void) generateFile: (NSString*) path withFormat: (NSString*) format;
- (NSString*) generateWithFormat: (NSString*) format;
@end
