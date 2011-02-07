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
- (void) generateImageFile: (NSString*) path;
@end
