#import "ETDrawingActionHandler.h"

@implementation ETActionHandler (ETDrawingActionHandler)

/**
 * item should be a new layout item created to contain the drawing stroke.
 * The item should have a size of (0,0), and be positioned at the point
 * where the drawing was initiated.
 */
- (void) handleBeginDrawStrokeOnItem: (ETLayoutItem *)item
                           withBrush: (ETStyle *)brush
{

}

- (void) handleContinueDrawStrokeOnItem: (ETLayoutItem *)item
                              withBrush: (ETStyle *)brush
                         withPointArray: (NSArray *)points
{
}

- (void) handleEndDrawStrokeOnItem: (ETLayoutItem *)item
                         withBrush: (ETStyle *)brush
                    withPointArray: (NSArray *)points
{
}
@end
