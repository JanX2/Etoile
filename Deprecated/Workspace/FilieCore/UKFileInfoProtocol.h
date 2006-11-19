/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFileInfoProtocol.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL, Modified BSD
    
    REVISIONS:
        2004-12-09  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Protocols:
// -----------------------------------------------------------------------------

/*
    Methods that a class implementing some sort of file info inspector needs to
    implement.
    
    Each delegate retains this object and releases it when it goes away.
*/

@protocol UKFileInfoProtocol

-(id)               initWithDelegates: (NSArray*)dels;

-(NSDictionary*)    fileAttributes;                         // The file attributes as currently being displayed (including user's changes). May contain UKFileInfoMixedValueIndicator objects if multiple selection. May return NIL.
-(void)             setFileAttributes: (NSDictionary*)dict; // Specify the file attributes to display. May contain UKFileInfoMixedValueIndicator objects if multiple selection. dict may be NIL to clear all attributes in preparation to reflecting a new selection.
-(void)             addFileAttributes: (NSDictionary*)dict; // Merges the current file attributes with dict, replacing any values that aren't the same with UKFileInfoMixedValueIndicator objects. Automatically sets the isMultipleSelection flag if it had to merge anything.

-(IBAction)         revert: (id)sender;                     // Sets file attributes to NIL, then sends provideAttributesToInfoController: to delegates to get their current attributes.
-(IBAction)         ok: (id)sender;                         // Sends takeAttributes:fromInfoController: to delegates apply the current attributes to them.
-(void)             reopen: (id)sender;                     // Focus or bring to front this info controller's GUI and call revert: so it contains current info.
-(void)             makeDelegatesResign;                    // Sends resignFromInfoController: to all delegates.

-(void)             setIsMultipleSelection: (BOOL)yorn;     // Panel should indicate that the selection contains several items.
-(BOOL)             isMultipleSelection;

-(NSArray*)         delegates;                              // Array of id<UKFileInfoDelegate> objects.
-(void)             setDelegates: (NSArray*)dels;           // Array of id<UKFileInfoDelegate> objects.
-(void)             addDelegate: (id)obj;                   // Is really id<UKFileInfoDelegate>, but protocols can't be forward-declared.
-(void)             removeDelegate: (id)obj;                // Is really id<UKFileInfoDelegate>, but protocols can't be forward-declared.

@end


/*
    Methods sent to the delegates:
*/

@protocol UKFileInfoDelegate

// When it gets this, each delegate should use addFileAttributes to add its attributes to the controller's:
-(void) provideAttributesToInfoController: (id<UKFileInfoProtocol>)infoController;

// When it gets this, each delegate should take the attributes passed (which should be the same as fileAttributes)
//  and apply them to itself. If any item is a UKFileInfoMixedValueIndicator (call isDifferentAcrossSelectedItems to
//  determine this easily), it should be ignored and the old value for this attribute be used.
-(void) takeAttributes: (NSDictionary*)attrs fromInfoController: (id<UKFileInfoProtocol>)infoController;

// Sent from the info controller to each delegate when the controller wants to go away.
//  E.g. if the user clicks the close box of an inspector.
-(void) resignFromInfoController: (id<UKFileInfoProtocol>)infoController;

@end

