#import "OSObject.h"

/* This is a virtual node, as OSNode to physical node.
   It use -pathRepresentation instead of -path 
   to avoid messying up with NSFilManager.
   Do not use this one. Subclass it.
 */
@interface OSVirtualNode: NSObject <OSObject>
{
  NSString *pathRep;
}

- (void) setPathRepresentation: (NSString *) rep;
- (NSString *) pathRepresentation;

@end

