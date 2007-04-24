/*
   PermissionsView.m
   The grid with permission check marks used in the permissions inspector.

   Copyright (C) 2005 Saso Kiselkov
                 2007 Yen-Ju Chen

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright notice, 
     this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice, 
     this list of conditions and the following disclaimer in the documentation 
     and/or other materials provided with the distribution.
   * Neither the name of the Etoile project nor the names of its contributors 
     may be used to endorse or promote products derived from this software 
     without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
   THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PermissionsView.h"

enum {
  UserField = 6,
  GroupField = 3,
  OtherField = 0,

  ReadField = 2,
  WriteField = 1,
  ExecuteField = 0
};

@implementation PermissionsView

- (void) dealloc
{
  DESTROY(check);
  DESTROY(cross);

  [super dealloc];
}

- (id) initWithFrame: (NSRect) frame
{
  self = [super initWithFrame: frame];

  NSBundle *bundle = [NSBundle bundleForClass: [self class]];

  check = [[NSImage alloc] initByReferencingFile: 
                  [bundle pathForResource: @"CheckMark" ofType: @"tiff"]];
  cross = [[NSImage alloc] initByReferencingFile: 
                  [bundle pathForResource: @"CrossMark" ofType: @"tiff"]];

  editable = YES;

  return self;
}

- (void) drawRect: (NSRect) r
{
  NSLog(@"Draw PrefView");
  NSSize s = [self frame].size;
  int xslot = s.width / 3;
  int yslot = displaysExecute ? s.height / 3 : s.height/2;
  int i;
  NSPoint p;

  PSsetgray(0.5);
  PSrectstroke(0.0, 0.0, s.width-1, s.height-1);

  for (i = 1; i <= 2; i++) 
  {
    PSmoveto(xslot*i, 0.0);
    PSlineto(xslot*i, s.height);
    PSstroke();
  }

  if (displaysExecute) 
  {
    PSmoveto(0.0, yslot*2);
    PSlineto(s.width, yslot*2);
    PSstroke();
  }

  PSmoveto(0.0, yslot);
  PSlineto(s.width, yslot);
  PSstroke();

  // user
  p = NSMakePoint(xslot*0.5 - 5, yslot * 0.5 + 5);
  if (mode & (1 << (UserField + ReadField)))
    [check compositeToPoint: p operation: NSCompositeSourceOver];
  else
    [cross compositeToPoint: p operation: NSCompositeSourceOver];

  p = NSMakePoint(xslot*1.5 - 5, yslot * 0.5 + 5);
  if (mode & (1 << (GroupField + ReadField)))
    [check compositeToPoint: p operation: NSCompositeSourceOver];
  else
    [cross compositeToPoint: p operation: NSCompositeSourceOver];

  p = NSMakePoint(xslot*2.5 - 5, yslot * 0.5 + 5);
  if (mode & (1 << (OtherField + ReadField)))
    [check compositeToPoint: p operation: NSCompositeSourceOver];
  else
    [cross compositeToPoint: p operation: NSCompositeSourceOver];

  // group
  p = NSMakePoint(xslot*0.5 - 5, yslot * 1.5 + 5);
  if (mode & (1 << (UserField + WriteField)))
    [check compositeToPoint: p operation: NSCompositeSourceOver];
  else
    [cross compositeToPoint: p operation: NSCompositeSourceOver];

  p = NSMakePoint(xslot*1.5 - 5, yslot * 1.5 + 5);
  if (mode & (1 << (GroupField + WriteField)))
    [check compositeToPoint: p operation: NSCompositeSourceOver];
  else
    [cross compositeToPoint: p operation: NSCompositeSourceOver];

  p = NSMakePoint(xslot*2.5 - 5, yslot * 1.5 + 5);
  if (mode & (1 << (OtherField + WriteField)))
    [check compositeToPoint: p operation: NSCompositeSourceOver];
  else
    [cross compositeToPoint: p operation: NSCompositeSourceOver];

  // other
  if (displaysExecute) 
  {
    p = NSMakePoint(xslot*0.5 - 5, yslot * 2.5 + 5);
    if (mode & (1 << (UserField + ExecuteField)))
      [check compositeToPoint: p operation: NSCompositeSourceOver];
    else
      [cross compositeToPoint: p operation: NSCompositeSourceOver];

    p = NSMakePoint(xslot*1.5 - 5, yslot * 2.5 + 5);
    if (mode & (1 << (GroupField + ExecuteField)))
      [check compositeToPoint: p operation: NSCompositeSourceOver];
    else
      [cross compositeToPoint: p operation: NSCompositeSourceOver];

    p = NSMakePoint(xslot*2.5 - 5, yslot * 2.5 + 5);
    if (mode & (1 << (OtherField + ExecuteField)))
      [check compositeToPoint: p operation: NSCompositeSourceOver];
    else
      [cross compositeToPoint: p operation: NSCompositeSourceOver];
  }
}

- (void) setMode: (unsigned) mod
{
  mode = mod;
  [self setNeedsDisplay: YES];
}

- (unsigned) mode
{
  return mode;
}

- (void) setDisplaysExecute: (BOOL) flag
{
  displaysExecute = flag;
  [self setNeedsDisplay: YES];
}

- (BOOL) displaysExecute
{
  return displaysExecute;
}

- (BOOL) acceptsFirstResponder
{
  return editable;
}

- (void) setTarget: (id) aTarget
{
  target = aTarget;
}

- (id) target
{
  return target;
}

- (void) setAction: (SEL) anAction
{
  action = anAction;
}

- (SEL) action
{
  return action;
}

- (void) setEditable: (BOOL) flag
{
  editable = flag;
}

- (BOOL) isEditable
{
  return editable;
}

- (void) mouseDown: (NSEvent *) ev
{
  NSPoint p;
  NSSize s = [self frame].size;
  unsigned userField;
  unsigned permField;

  if (editable == NO)
    return;

  p = [self convertPoint: [ev locationInWindow] fromView: nil];
  if (displaysExecute) 
  {
    p.y /= (s.height / 3);
    if (p.y < 1)
      permField = ReadField;
    else if (p.y > 1 && p.y < 2)
      permField = WriteField;
    else
      permField = ExecuteField;
  } 
  else 
  {
    p.y /= (s.height / 2);
    if (p.y < 1)
      permField = ReadField;
    else
      permField = WriteField;
  }

  p.x /= (s.width / 3);
  if (p.x < 1)
    userField = UserField;
  else if (p.x > 1 && p.x < 2)
    userField = GroupField;
  else
    userField = OtherField;

  if (mode & (1 << (userField + permField)))
    mode &= ~(1 << (userField + permField));
  else
    mode |= (1 << (userField + permField));

  [self setNeedsDisplay: YES];

  if (target != nil && action != NULL && [target respondsToSelector: action])
    [target performSelector: action withObject: self];
}

- (BOOL) isFlipped
{
  return YES;
}

@end
