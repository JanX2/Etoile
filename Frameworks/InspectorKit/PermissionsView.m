/*
   PermissionsView.m
   The grid with permission check marks used in the permissions inspector.

   This file is part of OpenSpace.

   Copyright (C) 2005 Saso Kiselkov

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
        TEST_RELEASE(check);
        TEST_RELEASE(cross);

        [super dealloc];
}

- initWithFrame: (NSRect) frame
{
        ASSIGN(check, [NSImage imageNamed: @"CheckMark"]);
        ASSIGN(cross, [NSImage imageNamed: @"CrossMark"]);

        editable = YES;

        return [super initWithFrame: frame];
}

- (void) drawRect: (NSRect) r
{
        NSSize s = [self frame].size;
        int xslot = s.width / 3;
        int yslot = displaysExecute ? s.height / 3 : s.height/2;
        int i;
        NSPoint p;

        PSsetgray(0.5);
        PSrectstroke(0.0, 0.0, s.width-1, s.height-1);

        for (i=1; i<=2; i++) {
                PSmoveto(xslot*i, 0.0);
                PSlineto(xslot*i, s.height);
                PSstroke();
        }

        if (displaysExecute) {
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
                [check compositeToPoint: p
                              operation: NSCompositeSourceOver];
        else
                [cross compositeToPoint: p
                              operation: NSCompositeSourceOver];

        p = NSMakePoint(xslot*1.5 - 5, yslot * 0.5 + 5);
        if (mode & (1 << (GroupField + ReadField)))
                [check compositeToPoint: p
                              operation: NSCompositeSourceOver];
        else
                [cross compositeToPoint: p
                              operation: NSCompositeSourceOver];

        p = NSMakePoint(xslot*2.5 - 5, yslot * 0.5 + 5);
        if (mode & (1 << (OtherField + ReadField)))
                [check compositeToPoint: p
                              operation: NSCompositeSourceOver];
        else
                [cross compositeToPoint: p
                              operation: NSCompositeSourceOver];

         // group
        p = NSMakePoint(xslot*0.5 - 5, yslot * 1.5 + 5);
        if (mode & (1 << (UserField + WriteField)))
                [check compositeToPoint: p
                              operation: NSCompositeSourceOver];
        else
                [cross compositeToPoint: p
                              operation: NSCompositeSourceOver];

        p = NSMakePoint(xslot*1.5 - 5, yslot * 1.5 + 5);
        if (mode & (1 << (GroupField + WriteField)))
                [check compositeToPoint: p
                              operation: NSCompositeSourceOver];
        else
                [cross compositeToPoint: p
                              operation: NSCompositeSourceOver];

        p = NSMakePoint(xslot*2.5 - 5, yslot * 1.5 + 5);
        if (mode & (1 << (OtherField + WriteField)))
                [check compositeToPoint: p
                              operation: NSCompositeSourceOver];
        else
                [cross compositeToPoint: p
                              operation: NSCompositeSourceOver];

         // other
        if (displaysExecute) {
                p = NSMakePoint(xslot*0.5 - 5, yslot * 2.5 + 5);
                if (mode & (1 << (UserField + ExecuteField)))
                        [check compositeToPoint: p
                                      operation: NSCompositeSourceOver];
                else
                        [cross compositeToPoint: p
                                      operation: NSCompositeSourceOver];

                p = NSMakePoint(xslot*1.5 - 5, yslot * 2.5 + 5);
                if (mode & (1 << (GroupField + ExecuteField)))
                        [check compositeToPoint: p
                                      operation: NSCompositeSourceOver];
                else
                        [cross compositeToPoint: p
                                      operation: NSCompositeSourceOver];

                p = NSMakePoint(xslot*2.5 - 5, yslot * 2.5 + 5);
                if (mode & (1 << (OtherField + ExecuteField)))
                        [check compositeToPoint: p
                                      operation: NSCompositeSourceOver];
                else
                        [cross compositeToPoint: p
                                      operation: NSCompositeSourceOver];
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

- (void) setTarget: aTarget
{
        target = aTarget;
}

- target
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
        if (displaysExecute) {
                p.y /= (s.height / 3);
                if (p.y < 1)
                        permField = ReadField;
                else if (p.y > 1 && p.y < 2)
                        permField = WriteField;
                else
                        permField = ExecuteField;
        } else {
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
