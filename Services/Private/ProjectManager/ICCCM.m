#import "ICCCM.h"

NSString* ICCCMWMName = @"WM_NAME";
NSString* ICCCMWMIconName = @"WM_ICON_NAME";
NSString* ICCCMWMNormalHints = @"WM_NORMAL_HINTS";
NSString* ICCCMWMSizeHints = @"WM_SIZE_HINTS";
NSString* ICCCMWMHints = @"WM_HINTS";
NSString* ICCCMWMClass = @"WM_CLASS";
NSString* ICCCMWMTransientFor = @"WM_TRANSIENT_FOR";
NSString* ICCCMWMProtocols = @"WM_PROTOCOLS";
NSString* ICCCMWMColormapWindows = @"WM_COLORMAP_WINDOWS";
NSString* ICCCMWMClientMachine = @"WM_CLIENT_MACHINE";

// Properties set by a Window Manager on a Client Window
NSString* ICCCMWMState = @"WM_STATE";
NSString* ICCCMWMIconSize = @"WM_ICON_SIZE";

// ICCCM WM_PROTOCOLS
NSString* ICCCMWMTakeFocus = @"WM_TAKE_FOCUS";
NSString* ICCCMWMSaveYourself = @"WM_SAVE_YOURSELF";
NSString* ICCCMWMDeleteWindow = @"WM_DELETE_WINDOW";

NSArray *ICCCMAtomsList(void)
{
	NSString* atoms[] = {
		ICCCMWMName,
		ICCCMWMIconName,
		ICCCMWMNormalHints, 
		ICCCMWMSizeHints, 
		ICCCMWMHints, 
		ICCCMWMClass, 
		ICCCMWMTransientFor, 
		ICCCMWMProtocols, 
		ICCCMWMColormapWindows, 
		ICCCMWMClientMachine, 
		ICCCMWMState, 
		ICCCMWMIconSize, 

		ICCCMWMTakeFocus, 
		ICCCMWMSaveYourself, 
		ICCCMWMDeleteWindow
	};
	// Remember, only works with static allocated arrays
	return [NSArray arrayWithObjects: atoms 
	                           count: sizeof(atoms) / sizeof(NSString*)];
}

@implementation XCBCachedProperty (ICCCM)
- (xcb_size_hints_t)asWMSizeHints
{
	xcb_size_hints_t size_hints;
	[self checkAtomType: ICCCMWMSizeHints];
	[[self data] getBytes: &size_hints
	               length: sizeof(xcb_size_hints_t)];
	return size_hints;
}
- (xcb_wm_hints_t)asWMHints
{
	xcb_wm_hints_t hints;
	[self checkAtomType: ICCCMWMHints];
	[[self data] getBytes: &hints
	               length: sizeof(xcb_wm_hints_t)];
	return hints;
}
@end

