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
@interface XMPPDiscoIdentity : NSObject {
	NSString * category;
	NSString * type;
	NSString * name;
}
+ (XMPPDiscoIdentity*) identityWithCategory:(NSString*)aCategory
									type:(NSString*)aType
									name:(NSString*)aName;
+ (XMPPDiscoIdentity*) identityWithXML:(ETXMLNode*)xml;
- (NSString*) category;
- (NSString*) type;
- (NSString*) name;
- (ETXMLNode*) toXML;
@end

@interface XMPPDiscoNode : NSObject {
	JID * jid;
	NSString * node;
	NSSet * identities;
	NSSet * features;
}

+ (XMPPDiscoNode*) discoNodeWithJID:(JID*)aJID
						   node:(NSString*)aNode
					 identities:(NSSet*)anIdentities
					   features:(NSSet*)aFeatures;
- (XMPPDiscoNode*) initWithJID:(JID*)aJID
					  node:(NSString*)aNode
				identities:(NSSet*)anIdentities
				  features:(NSSet*)aFeatures;
+ (XMPPDiscoNode*) discoNodeFromXML:(ETXMLNode*)xml;
- (XMPPDiscoNode*) initFromXML:(ETXMLNode*)xml;
- (NSString*) node;
- (NSSet*) features;
- (NSSet*) identities;
- (JID*) jid;
- (BOOL) supportsFeature:(NSString*)feature;
- (ETXMLNode*) toXML;
@end

@interface XMPPDiscoTreeNode : NSObject {
	JID * jid;
	NSString * name;
	NSString * node;
	NSSet * children;
}
+ (XMPPDiscoTreeNode*) discoTreeNodeWithJID:(JID*)aJID
								   name:(NSString*)aName
								   node:(NSString*)aNode;
- (XMPPDiscoTreeNode*) initWithJID:(JID*)aJID
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
