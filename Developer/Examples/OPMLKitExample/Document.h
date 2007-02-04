/* All Rights Reserved */

#ifndef _DOCUMENT_H_
#define _DOCUMENT_H_

#import <AppKit/AppKit.h>
#import <OPMLKit/OPMLDocument.h>

@interface Document : NSDocument
{
    IBOutlet NSOutlineView* outlineView;
    IBOutlet NSTextField* documentInfoLabel;
    
    OPMLDocument* opmlDocument;
}

- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType;
- (NSData *) dataRepresentationOfType: (NSString *) aType;

- (NSString *) windowNibName;


// -------------------------------------------------------------------
//    NSOutlineView data source
// -------------------------------------------------------------------

/**
 * Implementation of this method is required.  Returns the child at
 * the specified index for the given item.
 */
- (id)outlineView: (NSOutlineView *)outlineView
            child: (int)index
           ofItem: (id)item;
/**
 * This is a required method.  Returns whether or not the outline view
 * item specified is expandable or not.
 */
- (BOOL)outlineView: (NSOutlineView *)outlineView
   isItemExpandable: (id)item;
/*
 * This is a required method.  Returns the number of children of
 * the given item.
 */
- (int)outlineView: (NSOutlineView *)outlineView
numberOfChildrenOfItem: (id)item;

/**
 * This is a required method.  Returns the object corresponding to the
 * item representing it in the outline view.
 */
- (id)outlineView: (NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item;


@end

#endif // _DOCUMENT_H_
