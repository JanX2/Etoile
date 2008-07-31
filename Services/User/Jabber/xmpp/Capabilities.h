//
//  Capabilities.h
//  Jabber
//
//  Created by David Chisnall on 08/05/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JID.h"
#import <EtoileXML/ETXMLNode.h>

/**
 * Service Discovery node.  Not yet implemented; please feel free to modify this
 */
@interface DiscoIdentity : NSObject {
	NSString * category;
	NSString * type;
	NSString * name;
}
+ (DiscoIdentity*) identityWithCategory:(NSString*)aCategory
									type:(NSString*)aType
									name:(NSString*)aName;
+ (DiscoIdentity*) identityWithXML:(ETXMLNode*)xml;
- (NSString*) category;
- (NSString*) type;
- (NSString*) name;
- (ETXMLNode*) toXML;
@end

@interface DiscoNode : NSObject {
	JID * jid;
	NSString * node;
	NSSet * identities;
	NSSet * features;
}

+ (DiscoNode*) discoNodeWithJID:(JID*)aJID
						   node:(NSString*)aNode
					 identities:(NSSet*)anIdentities
					   features:(NSSet*)aFeatures;
- (DiscoNode*) initWithJID:(JID*)aJID
					  node:(NSString*)aNode
				identities:(NSSet*)anIdentities
				  features:(NSSet*)aFeatures;
+ (DiscoNode*) discoNodeFromXML:(ETXMLNode*)xml;
- (DiscoNode*) initFromXML:(ETXMLNode*)xml;
- (NSString*) node;
- (NSSet*) features;
- (NSSet*) identities;
- (JID*) jid;
- (BOOL) supportsFeature:(NSString*)feature;
- (ETXMLNode*) toXML;
@end

@interface DiscoTreeNode : NSObject {
	JID * jid;
	NSString * name;
	NSString * node;
	NSSet * children;
}
+ (DiscoTreeNode*) discoTreeNodeWithJID:(JID*)aJID
								   name:(NSString*)aName
								   node:(NSString*)aNode;
- (DiscoTreeNode*) initWithJID:(JID*)aJID
						  name:(NSString*)aName
						  node:(NSString*)aNode;
- (void) addChildrenFromXML:(ETXMLNode*)xml;
- (JID*) jid;
- (NSString*) name;
- (NSString*) node;
- (NSSet*) children;
- (ETXMLNode*) toXML;
- (ETXMLNode*) toXMLAsChild;
@end
