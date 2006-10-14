/*
   Project: RSSReader

   Copyright (C) 2005 Free Software Foundation

   Author: Guenther Noack,,,

   Created: 2005-03-27 00:21:32 +0000 by guenther

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/


/*
 * I learned how to do the Drag&Drop stuff from
 * http://cocoadevcentral.com/articles/000056.php
 * and by reading the Apple AppKit API Reference
 * in addition to this.
 */

#import <RSSKit/RSSKit.h>
#import "RSSReaderFeed.h"
#import "RSSReaderArticle.h"

#import "RSSDropZone.h"
#import "FeedList.h"


/* Handles the base pasteboard functionality.
 * This function is also called from the file RSSReaderService.m
 */
BOOL addFeedsFromPasteboard( NSPasteboard* pasteboard )
{
  NSArray*      types;
  NSString*     desiredType;
  NSData*       carriedData;
  
  types = [NSArray arrayWithObjects:
		     NSFilenamesPboardType, NSURLPboardType, nil];
  
  desiredType = [pasteboard availableTypeFromArray: types];
  
  carriedData = [pasteboard dataForType: desiredType];
  
  if (nil==carriedData)
    {
      NSRunAlertPanel(@"Can't drop this",
		      @"I'm sorry. The paste operation failed.",
		      nil, nil, nil);
      return NO;
    }
  else
    {
      if ([desiredType isEqualToString: NSFilenamesPboardType])
	{
	  NSArray *filenameArray;
	  NSMutableArray *feedArray;
	  int i;
	  
	  // get the dropped file names
	  filenameArray = 
	    [pasteboard propertyListForType: NSFilenamesPboardType];
	  NSLog(@"<DROP> filenames: %@", filenameArray);
	  
	  // create an autoreleased array for the corresponding
	  // feed objects.
	  feedArray =
	    [NSMutableArray arrayWithCapacity: [filenameArray count]];
	  
	  for (i=0; i<[filenameArray count]; i++)
	    {
	      NSString* filename;
	      NSURL* url;
	      RSSFeed* feed;
	      
	      filename = [filenameArray objectAtIndex: i];
	      
	      url = [NSURL fileURLWithPath: filename];
	      
	      feed = AUTORELEASE([[RSSReaderFeed alloc] initWithURL:url]);
	      [feed setAutoClear: NO];
	      [feedArray addObject: feed];
	    }
	  
	  [getFeedList() addFeeds: feedArray];
	}
      else if ([desiredType isEqualToString: NSURLPboardType])
	{
	  NSURL* url = [NSURL URLFromPasteboard: pasteboard];
	  
	  if (url != nil)
	    {
	      [getFeedList() addFeedWithURL: url];
	    }
	}
      else
	{
	  NSRunAlertPanel(@"Something *very* strange happened",
			  @"This operation failed in a *very* "
			  @"strange way. This just isn't possible.",
			  nil, nil, nil);
	  return NO;
	}
    }
  
  return YES;
}

/* -------------------------------------------------------------- */
/*                       dragging interface                       */
/* -------------------------------------------------------------- */


@interface RSSDropZone (NSDraggingDestination)

//
// Before the Image is Released
//
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender;
// - (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender;
// - (void)draggingExited:(id <NSDraggingInfo>)sender;

//
// After the Image is Released
//
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
// - (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

#ifndef STRICT_OPENSTEP
// - (void)draggingEnded: (id <NSDraggingInfo>)sender;
#endif

@end



/* -------------------------------------------------------------- */
/*                     dragging implementation                    */
/* -------------------------------------------------------------- */


@implementation RSSDropZone (NSDraggingDestination)

// ############################
// Before the Image is Released
// ############################

/* We accept generic Dragging operations.
 */
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
{
  NSLog(@"dragging Entered (%d)",
	[sender draggingSourceOperationMask]);
  
  if ((NSDragOperationLink & [sender draggingSourceOperationMask])
      == NSDragOperationLink)
    {
      NSLog(@"We like this (linked) file");
      return NSDragOperationLink;
    }
  else if ((NSDragOperationPrivate & [sender draggingSourceOperationMask])
	   == NSDragOperationPrivate)
    {
      NSLog(@"We like this (private) file");
      return NSDragOperationCopy;
    }
  else if ((NSDragOperationGeneric & [sender draggingSourceOperationMask])
	   == NSDragOperationGeneric)
    {
      NSLog(@"We like this (generic copied) file");
      return NSDragOperationCopy;
    }
  else if ((NSDragOperationCopy & [sender draggingSourceOperationMask])
	   == NSDragOperationCopy)
    {
      NSLog(@"We like this (copied) file");
      return NSDragOperationCopy;
    }
  else
    {
      NSLog(@"We don't like this file");
      return NSDragOperationNone;
    }
}


/* We won't override this, because then the standard one
 * returns the same value as draggingEntered: did. (That's
 * what this article said.)
 */

// - (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender;


/* This method is simply not interesting for us.
 */
// - (void)draggingExited:(id <NSDraggingInfo>)sender;


// ###########################
// After the Image is Released
// ###########################

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return YES;
}

/*  */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  NSPasteboard* pasteboard;
  
  NSLog(@"perform Drag Operation");
  
  pasteboard = [sender draggingPasteboard];
  
  return addFeedsFromPasteboard(pasteboard);
}

/* not interesting for us. */
// - (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

#ifndef STRICT_OPENSTEP
/* not interesting for us. */
// - (void)draggingEnded: (id <NSDraggingInfo>)sender;
#endif

@end




/* -------------------------------------------------------------- */
/*                         the class itself                       */
/* -------------------------------------------------------------- */


@implementation RSSDropZone

-(id) initWithFrame: (NSRect) frame
{
  
  if ((self = [super initWithFrame: frame]))
    {
      NSLog(@"registering");
      [self registerForDraggedTypes:
	      [NSArray arrayWithObjects:
			 NSFilenamesPboardType, NSURLPboardType, nil] ];
    }
  
  return self;
}


-(void) dealloc
{
  [self unregisterDraggedTypes];
  [super dealloc];
}

@end

