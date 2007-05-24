/* FMController */

#import <Cocoa/Cocoa.h>
#import "FMSampleController.h"

@interface FMController : NSObject
{
    IBOutlet NSOutlineView *fontList;
    IBOutlet NSTableView *groupList;
    IBOutlet FMSampleController *sampleController;
}
@end
