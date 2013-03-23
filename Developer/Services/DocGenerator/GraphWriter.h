#import <Foundation/Foundation.h>
#ifdef __APPLE__
// NOTE: For solving an ObjC header conflict on some Mac OS X versions (10.6)
#undef TRUE
#endif
#include <graphviz/gvc.h>

/** @group Model and Metamodel

Abstract base class used by Model Description core classes.

Also implements NestedElement and NamedElement protocols that exist in FAME/EMOF.

@section FAME Teminology Change Summary

Those changes were made to further simplify the FAME terminology which can get
obscure since it overlaps with the host language object model, prevent any
conflict with existing GNUstep/Cocoa API and reuse GNUstep/Cocoa naming habits.

We list the FAME term first, then its equivalent name in EtoileFoundation:

<deflist>
<term>FM3.Element</term><desc>ETModelElementDescription</desc>
<term>FM3.Class</term><desc>ETEntityDescription</desc>
<term>FM3.Property</term><desc>ETPropertyDescription</desc>
<term>FM3.RuntimeElement</term><desc>ETAdaptiveModelObject</desc>
<term>attributes (in Class)</term><desc>propertyDescriptions (in ETEntityDescription)</desc>
<term>allAttributes (in Class)</term><desc>allPropertyDescriptions (in ETEntityDescription)</desc>
<term>superclass (in Class)</term><desc>parent (in ETEntityDescription)</desc>
<term>class (in Property)</term><desc>owner (in ETPropertyDescription)</desc>
</deflist>

For the last point class vs owner, we can consider they have been merged into
a single property in EtoileFoundation since they were redundant.

@section Additions to FAME

itemIdentifier has been added as a mean to get precise control over the UI
generation with EtoileUI.

@section Removals to FAME/EMOF

NamedElement and NestedElement protocols don't exist explicitly. */
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
