/* All Rights Reserved */

#import "Document.h"
#import <AppKit/AppKit.h>

NSString* const OPMLOutlinePboardType = @"OPMLOutlinePboardType";
NSString* const OPMLOutlineReferencePboardType = @"OPMLOutlineReferencePboardType";

@implementation Document

// --------------------------------------------------------------------
//    Awaking from Nib loading
// --------------------------------------------------------------------

-(void) awakeFromNib
{
    NSLog(@"Outline view: %@", outlineView);
    [outlineView registerForDraggedTypes: [NSArray arrayWithObject: NSURLPboardType]];
}

// --------------------------------------------------------------------
//    Document methods
// --------------------------------------------------------------------

- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType
{
  ASSIGN(opmlDocument, [OPMLDocument documentWithData: data]);
  
  if (opmlDocument) {
      NSLog(@"Document %@", opmlDocument);
      NSLog(@"Title: %@", [opmlDocument title]);
      NSLog(@"Owner: %@ (%@)", [opmlDocument ownerName], [opmlDocument ownerEmail]);
      NSLog(@"#Outlines: %d", [opmlDocument outlineCount]);
      
      [documentInfoLabel setStringValue: [NSString stringWithFormat:
          @"Author: %@ (%@)",
          [opmlDocument ownerName],
          [opmlDocument ownerEmail]
      ]];
  }
  
  return (opmlDocument != nil) ? YES : NO;
}

- (NSData *) dataRepresentationOfType: (NSString *) aType
{
  /* Insert code here to return a data representation of your document. */
  
  // Saving does not work yet.
  
  return nil;
}

- (NSString *) displayName
{
    return [opmlDocument title];
}

- (NSString *) windowNibName
{
  return @"Document";
}

// -------------------------------------------------------------------
//    NSOutlineView data source
// -------------------------------------------------------------------

/**
 * Implementation of this method is required.  Returns the child at
 * the specified index for the given item.
 */
- (id)outlineView: (NSOutlineView *)outlineView
            child: (int)index
           ofItem: (id)item
{
    if (item == nil) { // root elem = document
        return [opmlDocument outlineAtIndex: index];
    } else {
        NSParameterAssert([item isKindOfClass: [OPMLOutline class]]);
        return [(OPMLOutline*)item outlineAtIndex: index];
    }
}

/**
 * This is a required method.  Returns whether or not the outline view
 * item specified is expandable or not.
 */
- (BOOL)outlineView: (NSOutlineView *)outlineView
   isItemExpandable: (id)item
{
    if (item == nil) { // root elem = document
        // TODO: Is this branch ever taken?
        return ([opmlDocument outlineCount] > 0) ? YES : NO;
    } else {
        NSParameterAssert([item isKindOfClass: [OPMLOutline class]]);
        return ([item outlineCount] > 0) ? YES : NO;
    }
}

/*
 * This is a required method.  Returns the number of children of
 * the given item.
 */
- (int)outlineView: (NSOutlineView *)outlineView
numberOfChildrenOfItem: (id)item
{
    if (item == nil) { // root elem = document
        return [opmlDocument outlineCount];
    } else {
        NSParameterAssert([item isKindOfClass: [OPMLOutline class]]);
        return [item outlineCount];
    }
}

/**
 * This is a required method.  Returns the object corresponding to the
 * item representing it in the outline view.
 */
- (id)outlineView: (NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item
{
    NSParameterAssert([item isKindOfClass: [OPMLOutline class]]);
    
    if ([[tableColumn identifier] isEqualToString: @"url"]) {
        return [item URL];
    } else {
        return [item text];
    }
}

// ---------------------------------------------------------------------
//    dropping things on the outline view
// ---------------------------------------------------------------------

- (NSDragOperation)outlineView: (NSOutlineView*)outlineView
                  validateDrop: (id <NSDraggingInfo>)info
                  proposedItem: (id)item
            proposedChildIndex: (int)index
{
    NSLog(@"-validateDrop:");
    NSPasteboard* pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject: NSURLPboardType]) {
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)outlineView: (NSOutlineView *)outlineView
         acceptDrop: (id <NSDraggingInfo>)info
               item: (id)item
         childIndex: (int)index
{
    NSLog(@"-acceptDrop:");
    NSPasteboard* pboard = [info draggingPasteboard];
    NSAssert(
        [[pboard types] containsObject: NSURLPboardType],
        @"dragging pboard didn't support NSURL pboard type"
    );
    NSURL* url = [NSURL URLFromPasteboard: pboard];
    
    NSLog(@"Dropped URL %@", url);
    return YES;
}

// ---------------------------------------------------------------------
//    dragging things from the outline view
// ---------------------------------------------------------------------

- (BOOL)outlineView: (NSOutlineView *)outlineView
         writeItems: (NSArray*)items
       toPasteboard: (NSPasteboard*)pboard
{
    if ([items count] != 1) {
        return NO;
    }
    
    OPMLOutline* outline = [items objectAtIndex: 0];
    NSURL* url = [NSURL URLWithString: [outline valueForKey: @"url"]];
    
    if (url == nil) {
        return NO;
    }
    
    [pboard declareTypes: [NSArray arrayWithObjects:
        NSURLPboardType,
        nil
    ] owner: nil];
    
    [url writeToPasteboard: pboard];
    
    return YES;
}

@end

