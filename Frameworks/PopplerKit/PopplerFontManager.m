/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
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

#import "PopplerFontManager.h"
#import "PopplerKitFunctions.h"

/* Default fonts which are included in the PopplerKit framework  */
static NSString* IncludedFonts [] = {
   @"n022003l.pfb", // Courier
   @"n022004l.pfb", // Courier-Bold
   @"n022024l.pfb", // Courier-BoldOblique
   @"n022023l.pfb", // Courier-Oblique
   @"n019003l.pfb", // Helvetica
   @"n019004l.pfb", // Helvetica-Bold
   @"n019024l.pfb", // Helvetica-BoldOblique
   @"n019023l.pfb", // Helvetica-Oblique
   @"s050000l.pfb", // Symbol
   @"n021004l.pfb", // Times-Bold
   @"n021024l.pfb", // Times-BoldItalic
   @"n021023l.pfb", // Times-Italic
   @"n021003l.pfb", // Times-Roman
   @"d050000l.pfb", // ZapfDingbats
   nil
};

/* The shared PopplerFontManager instance.  */
static PopplerFontManager* sharedPopplerFontManager = nil;

/*
 * Non-Public methods.
 */
@interface PopplerFontManager(Private)
- (void) _addIncludedFonts;
- (NSString*) _findIncludedFontFile: (NSString*)aBaseFile;
@end


@implementation PopplerFontManager

- (id) init
{
   self = [super init];
   if (self)
   {
      fonts = [[NSMutableArray alloc] initWithCapacity: 0];
      [self _addIncludedFonts];
   }

   return self;
}

- (void) dealloc
{
   [fonts release];
   [super dealloc];
}

+ (PopplerFontManager*) sharedManager
{
   if (!sharedPopplerFontManager)
   {
      NS_DURING
         sharedPopplerFontManager = [[PopplerFontManager alloc] init];
      NS_HANDLER
         NSLog(@"Unable to obtain a PopplerFontManager instance: %@",
               [localException reason]);
         sharedPopplerFontManager = nil;
      NS_ENDHANDLER
   }

   return sharedPopplerFontManager;
}

- (NSArray*) fonts
{
   return [NSArray arrayWithArray: fonts];
}

- (void) addFontFile: (NSString*)aFont
{
   NSAssert(aFont, @"nil font");

   // check   
   BOOL isDir = NO;
   NSFileManager* fm = [NSFileManager defaultManager];
   if (![fm fileExistsAtPath: aFont isDirectory: &isDir])
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"font file %@ not found!", aFont];
   }
   if (isDir)
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"font file %@ is a directory!", aFont];
   }
   
   // register
   [fonts addObject: aFont];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerFontManager (Private)

- (void) _addIncludedFonts
{
   int i;
   for (i = 0; IncludedFonts[i]; i++)
   {
      NSString* fontFile = [self _findIncludedFontFile: IncludedFonts[i]];
      if (fontFile)
      {
         [self addFontFile: fontFile];
         NSLog(@"added font %@", IncludedFonts[i]);
      }
      else
      {
         NSLog(@"WARNING: no font for %@", IncludedFonts[i]);
      }
   }
}

- (NSString*) _findIncludedFontFile: (NSString*)aBaseFile
{
   NSBundle* bundle;
   NSString* pathToFile;
   
   bundle = [NSBundle bundleForClass: [PopplerFontManager class]];
   NSAssert(bundle, @"Failed to detect PopplerKit Bundle");

   pathToFile = [bundle pathForResource: [aBaseFile stringByDeletingPathExtension]
                                 ofType: [aBaseFile pathExtension]];

   if (!pathToFile)
   {
      NSLog(@"WARNING: Resource %@ of type %@ not found",
            [aBaseFile stringByDeletingPathExtension],
            [aBaseFile pathExtension]);
   }

   return pathToFile;
}

@end
