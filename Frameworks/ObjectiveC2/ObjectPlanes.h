#import <Foundation/NSObject.h>


/**
 * ETObjectPlane provides a concrete implementation of planes.
 */
@interface ETObjectPlane : NSObject {
	@public 
	IMP (*intercept)(id, id, SEL, id, id);
	@protected
	NSZone *zone;
	unsigned int index;
}
/**
 * The NSZone containing objects in this plane.
 */
- (NSZone*)zoneForPlane;
/**
 * Returns a unique identifier for the plane.  The current implementation is
 * limited to 2^16 object planes.
 */
- (unsigned short)planeID;

@end
@interface NSObject (ObjectPlanes)
/**
 * Creates a new object in the specific plane.
 */
+ (id)allocInPlane: (ETObjectPlane*)aPlane;
/**
 * Returns the plane hosting this object.
 */
- (ETObjectPlane*)objectPlane;
@end

@protocol ETPlaneAwareCopying
/**
 * Creates a copy of the object in the specified plane.
 */
- (id)copyToPlane: (ETObjectPlane*)aPlane;
@end

