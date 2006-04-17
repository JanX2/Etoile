/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   translate.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   translate.c for the Openbox window manager
   Copyright (c) 2004        Mikael Magnusson
   Copyright (c) 2003        Ben Jansens

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   See the COPYING file for a copy of the GNU General Public License.
*/

#import "translate.h"
#import "openbox.h"
#import "stdlib.h"

#define iCompare(a, x) \
	([a compare: x options: NSCaseInsensitiveSearch] == NSOrderedSame)

static unsigned int translate_modifier(NSString *str)
{
    if (iCompare(str, @"Mod1") || iCompare(str, @"A")) return Mod1Mask;
    else if (iCompare(str, @"Mod2")) return Mod2Mask;
    else if (iCompare(str, @"Mod3") || iCompare(str, @"M")) return Mod3Mask;
    else if (iCompare(str, @"Mod4") || iCompare(str, @"W")) return Mod4Mask;
    else if (iCompare(str, @"Mod5")) return Mod5Mask;
    else if (iCompare(str, @"Control") || iCompare(str, @"C")) return ControlMask;
    else if (iCompare(str, @"Shift") || iCompare(str, @"S")) return ShiftMask;
    NSLog(@"Warning: Invalide modifier '%@' in binding.", str);
    return 0;
}

BOOL translate_button(NSString *str, unsigned int *state, unsigned int *button)
{
    NSArray *parsed;
    NSString *l;
    int i;
    BOOL ret = NO;

    parsed = [str componentsSeparatedByString: @"-"];
    if ([parsed count] == 0)
      goto translation_fail;
    
    /* first, find the button (last token) */
    l = [parsed lastObject];

    /* figure out the mod mask */
    *state = 0;
    for (i = 0; i < [parsed count]-1; ++i) {
        unsigned int m = translate_modifier([parsed objectAtIndex: i]);
        if (!m) goto translation_fail;
        *state |= m;
    }

    /* figure out the button */
    if (iCompare(l, @"Left")) *button = 1;
    else if (iCompare(l, @"Middle")) *button = 2;
    else if (iCompare(l, @"Right")) *button = 3;
    else if (iCompare(l, @"Up")) *button = 4;
    else if (iCompare(l, @"Down")) *button = 5;
    else if ([@"Button" compare: l options: NSCaseInsensitiveSearch range: NSMakeRange(0, 6)] == NSOrderedSame) {
      *button = [[l substringFromIndex: 6] intValue];
    }
    if (!*button) {
	NSLog(@"Invalid button '%@' in pointer binding.", l);
        goto translation_fail;
    }

    ret = YES;

translation_fail:
    return ret;
}

BOOL translate_key(NSString *str, unsigned int *state, unsigned int *keycode)
{
    NSArray *parsed;
    NSString *l;
    int i;
    BOOL ret = NO;
    KeySym sym;

    parsed = [str componentsSeparatedByString: @"-"];
    if ([parsed count] == 0)
      goto translation_fail;
    
    /* first, find the key (last token) */
    l = [parsed lastObject];

    /* figure out the mod mask */
    *state = 0;
    for (i = 0; i < [parsed count]-1; ++i) {
        unsigned int m = translate_modifier([parsed objectAtIndex: i]);
        if (!m) goto translation_fail;
        *state |= m;
    }
    
    if ([@"0x" compare: l options: NSCaseInsensitiveSearch range: NSMakeRange(0, 2)] == NSOrderedSame) {
        char *end;

        /* take it directly */
        *keycode = strtol([l cString], &end, 16);
        if (*end != '\0') {
	    NSLog(@"Warning: Invalid key code '%@' in key binding.", l);
            goto translation_fail;
        }
    } else {
        /* figure out the keycode */
        sym = XStringToKeysym([l cString]);
        if (sym == NoSymbol) {
	    NSLog(@"Warning: Invalid key code '%@' in key binding.", l);
            goto translation_fail;
        }
        *keycode = XKeysymToKeycode(ob_display, sym);
    }
    if (!*keycode) {
        NSLog(@"Key '%@' does not exist on the display.", l); 
        goto translation_fail;
    }

    ret = YES;

translation_fail:
    return ret;
}
