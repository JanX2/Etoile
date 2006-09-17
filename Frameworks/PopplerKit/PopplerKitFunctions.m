/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "PopplerKitFunctions.h"
#import "PopplerDocument.h"
#import "PopplerFontManager.h"

#include "bindings/poppler.h"

static BOOL initialized = NO;

BOOL PopplerKitInit(void)
{
   int init_rc = 0;
   
   if (initialized)
   {
      return YES;
   }
   
   // handle additional fonts
   NSArray* addFonts = [[PopplerFontManager sharedManager] fonts];
   unsigned naddFonts = [addFonts count];
   const unsigned char** addFontsP = NULL;
   if (naddFonts > 0)
   {
      addFontsP = NSZoneMalloc(NSDefaultMallocZone(),
                               naddFonts * sizeof (unsigned char*));
      int i;
      for (i = 0; i < naddFonts; i++)
      {
         addFontsP[i] = (const unsigned char*)[[addFonts objectAtIndex: i] cString];
      }
   }
   
#ifdef GNUSTEP
   init_rc =  poppler_init(NULL, addFontsP, naddFonts);
#else
   NSBundle* bundle = [NSBundle bundleForClass: [PopplerDocument class]];
   NSString* fcConfigFile = [bundle pathForResource: @"fonts" ofType: @"conf"];
   init_rc = poppler_init((const unsigned char*)[fcConfigFile cString], addFontsP, naddFonts);
#endif

   if (addFontsP != NULL)
   {
      NSZoneFree(NSDefaultMallocZone(), addFontsP);
   }

   if (init_rc != 0)
   {
      NSLog(@"PopplerKit Initialization SUCCEEDED");
   }
   else
   {
      NSLog(@"PopplerKit Initialization FAILED: poppler_init FAILED!!");
   }

   initialized = (init_rc != 0);
   return initialized;
}

NSSize PopplerKitDPI(void)
{
   //NSDictionary* device = [[NSScreen mainScreen] deviceDescription];
   //return [[device objectForKey: NSDeviceResolution] sizeValue];
   return NSMakeSize(72.0, 72.0);
}

