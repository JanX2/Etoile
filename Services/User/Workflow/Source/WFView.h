/*
 * WFView.h - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 03/27/07
 * License: Modified BSD license (see file COPYING)
 */


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


/*
 * WFView (Class)
 *
 * Provides a graphical data-flow diagram which can be viewed/changed. Main
 * view for Workflow.
 */
@interface WFView : NSView
{
	id delagate;
	id dataSource;
	BOOL isEditable;

	/* Pipe values */
	float pipeWidth; /* px */
	NSColor *pipeColor;
	NSColor *pipeBorderColor;

	/* Grid values */
	float gridLineWidth; /* px */
	float gridSpacing; /* px */
	NSColor *gridColor;
}

- (id) dataSource;
- (void) setDataSource: (id)anObject;

@end


/*
 * WFDataSource (Informal Protocol)
 *
 * Informal protocal for WFView's data source.
 */
@interface NSObject (WFDataSource)

/* Required */
- (NSSet *) objectsForWorkflowView: (WFView *)workflowView;

/* Required for editable view */
- (void) workflowView: (WFView *)workflowView
             setValue: (id)newValue
            forObject: (id)oldValue;

@end

