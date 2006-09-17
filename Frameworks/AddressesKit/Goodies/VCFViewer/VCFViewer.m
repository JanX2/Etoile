// VCFViewer.m (this is -*- ObjC -*-)
// 
// \author: Bj�rn Giesler <giesler@ira.uka.de>
// 
// VCF Content Viewer for GWorkspace
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:03 $

/* system includes */
/* (none) */

/* my includes */
#include "VCFViewer.h"

@implementation VCFViewer
- (id) initInPanel: (id) aPanel
	 withFrame: (NSRect) frame
	     index: (int) idx
{
  [super init];

  sv = [[[NSScrollView alloc] initWithFrame: NSMakeRect(0, 30, 257, 215)]
	 autorelease];
  [sv setHasVerticalScroller: YES];
  [sv setHasHorizontalScroller: YES];
  [sv setBorderType: NSBezelBorder];
  [self addSubview: sv];

  cv = [[[NSClipView alloc] initWithFrame: [sv frame]] autorelease];
  [cv setAutoresizesSubviews: YES];
  [sv setContentView: cv];

  pv = [[[ADPersonView alloc] initWithFrame: NSZeroRect] autorelease];
  [pv setFillsSuperview: YES];
  [pv setFontSize: 6.0];
  [pv setAcceptsDrop: NO];
  [pv setDelegate: self];
  [cv setDocumentView: pv];

  pb = [[[NSButton alloc] initWithFrame: NSMakeRect(80, 0, 20, 20)]
	 autorelease];
  [pb setImage: [NSImage imageNamed: @"common_ArrowLeft"]];
  [pb setImagePosition: NSImageOnly];
  [pb setTarget: self];
  [pb setAction: @selector(previousPerson:)];
  [self addSubview: pb];

  lbl = [[[NSTextField alloc] initWithFrame: NSMakeRect(100, 0, 57, 20)]
	  autorelease];
  [lbl setEditable: NO];
  [lbl setSelectable: NO];
  [lbl setBezeled: NO];
  [lbl setDrawsBackground: NO];
  [lbl setAlignment: NSCenterTextAlignment];
  [self addSubview: lbl];

  nb = [[[NSButton alloc] initWithFrame: NSMakeRect(157, 0, 20, 20)]
	 autorelease];
  [nb setImage: [NSImage imageNamed: @"common_ArrowRight"]];
  [nb setImagePosition: NSImageOnly];
  [nb setTarget: self];
  [nb setAction: @selector(nextPerson:)];
  [self addSubview: nb];

  dfb = [[[NSButton alloc] initWithFrame: NSMakeRect(215, 0, 20, 20)]
	  autorelease];
  [dfb setTitle: @"-"];
  [dfb setTarget: self];
  [dfb setAction: @selector(decreaseFontSize:)];
  [dfb setContinuous: YES];
  [self addSubview: dfb];

  ifb = [[[NSButton alloc] initWithFrame: NSMakeRect(237, 0, 20, 20)]
	  autorelease];
  [ifb setTitle: @"+"];
  [ifb setTarget: self];
  [ifb setAction: @selector(increaseFontSize:)];
  [ifb setContinuous: YES];
  [self addSubview: ifb];

  people = nil;
  bundlePath = nil;
  
  return self;
}

- (void) setBundlePath: (NSString*) path
{
  [bundlePath release];
  bundlePath = [path copy];
}

- (NSString*) bundlePath
{
  return bundlePath;
}

- (void) setIndex: (int) idx
{
  index = idx;
}

- (void) activateForPath: (NSString*) path
{
  id conv;
  NSMutableArray *ppl;
  ADRecord *r;

  conv = [[ADConverterManager sharedManager]
	   inputConverterWithFile: path];
  [people release];
  ppl = [NSMutableArray array];

  while((r = [conv nextRecord]))
    if([r isKindOfClass: [ADPerson class]])
      [ppl addObject: r];
  people = [[NSArray alloc] initWithArray: ppl];
  
  currentPerson = 0;
  if([people count])
    {
      [pv setPerson: [people objectAtIndex: currentPerson]];
      [ifb setEnabled: YES];
      [dfb setEnabled: YES];
      [lbl setStringValue: [NSString stringWithFormat: @"%d/%d",
				     currentPerson+1, [people count]]];
    }
  else
    {
      [pv setPerson: nil];
      [ifb setEnabled: NO];
      [dfb setEnabled: NO];
      [lbl setStringValue: [NSString stringWithFormat: @"%d/%d",
				     currentPerson+1, [people count]]];
    }

  if([people count] > 1)
    {
      [nb setEnabled: YES];
      [pb setEnabled: YES];
    }
  else
    {
      [nb setEnabled: NO];
      [pb setEnabled: NO];
    }

  [sv setNeedsDisplay: YES];
}

- (BOOL) displayData: (NSData*) data
	      ofType: (NSString*) type
{
  return NO;
}

- (BOOL) stopTasks
{
  return YES;
}

- (void) deactivate
{
  [self removeFromSuperview];
}

- (BOOL)canDisplayFileAtPath:(NSString *)path
{
  if([[NSArray arrayWithObjects: @"vcf", @"vcard", nil]
       containsObject: [[path pathExtension] lowercaseString]])
    return YES;
  return NO;
}

- (BOOL)canDisplayData:(NSData *)data ofType:(NSString *)type
{
  return NO;
}

- (int)index
{
  return index;
}

- (NSString *)winname
{
  return NSLocalizedString(@"VCF Inspector", @"");
}

- (void) nextPerson: (id) sender
{
  currentPerson++;
  if(currentPerson > [people count]-1)
    currentPerson = 0;

  if([people count])
    [pv setPerson: [people objectAtIndex: currentPerson]];
  else
    [pv setPerson: nil];
  [lbl setStringValue: [NSString stringWithFormat: @"%d/%d",
				 currentPerson+1, [people count]]];
}

- (void) previousPerson: (id) sender
{
  currentPerson--;
  if(currentPerson < 0)
    currentPerson = [people count]-1;
  
  if([people count])
    [pv setPerson: [people objectAtIndex: currentPerson]];
  else
    [pv setPerson: nil];
  
  [lbl setStringValue: [NSString stringWithFormat: @"%d/%d",
				 currentPerson+1, [people count]]];
}

- (void) increaseFontSize: (id) sender
{
  [pv setFontSize: [pv fontSize]+2];
  if([pv fontSize] > 2)
    [dfb setEnabled: YES];
}

- (void) decreaseFontSize: (id) sender
{
  if([pv fontSize] <= 2) return;
  [pv setFontSize: [pv fontSize]-2];
  if([pv fontSize] <= 2)
    [dfb setEnabled: NO];
}

//
// Delegate stuff
//
- (BOOL) personView: (ADPersonView*) aView
     willDragPerson: (ADPerson*) person
{
  return YES;
}

- (BOOL) personView: (ADPersonView*) aView
   willDragProperty: (NSString*) property
{
  return NO;
}

@end
