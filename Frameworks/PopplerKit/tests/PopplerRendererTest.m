
#import "PopplerRendererTest.h"
#import "TestSettings.h"

@implementation PopplerRendererTest

- (void) setUp
{
   document = [[PopplerDocument alloc] initWithPath: kTestDocument];
   [[NSFileManager defaultManager] createDirectoryAtPath: kTestRenderDirectory
                                              attributes: nil];
}

- (void) tearDown
{
   [document release];
}

- (void) testSplashRendererFullPage
{
   PopplerSplashRenderer* renderer = 
      [[PopplerSplashRenderer alloc] initWithDocument: document];
   [renderer autorelease];
   
   PopplerPage* page = [document page: 1];
   NSBitmapImageRep* imageRep = [renderer renderPage: page scale: 1.0];
   [self assertNotNil: imageRep];
   [self assertInt: [imageRep retainCount] equals: 1];
   [self assertTrue: [self saveAsTIFF: imageRep file: @"splash-page.tiff"]];
}

- (void) testSplashRenderSlice
{
   PopplerSplashRenderer* renderer = 
      [[PopplerSplashRenderer alloc] initWithDocument: document];
   [renderer autorelease];

   PopplerPage* page = [document page: 1];
   NSRect box;
   box.origin = NSMakePoint(100, 100);
   box.size.width = [page size].width - 100;
   box.size.height = [page size].height - 100;
   
   NSBitmapImageRep* imageRep = [renderer renderPage: page srcBox: box scale: 1.0];
   [self assertNotNil: imageRep];
   [self assertInt: [imageRep retainCount] equals: 1];
   [self assertTrue: [self saveAsTIFF: imageRep file: @"splash-slice.tiff"]];
}

- (void) testSplashRenderScaled
{
   PopplerSplashRenderer* renderer = 
      [[PopplerSplashRenderer alloc] initWithDocument: document];
   [renderer autorelease];

   PopplerPage* page = [document page: 1];
   NSBitmapImageRep* imageRep = [renderer renderPage: page scale: 0.5];
   [self assertNotNil: imageRep];
   [self assertInt: [imageRep retainCount] equals: 1];
   [self assertTrue: [self saveAsTIFF: imageRep file: @"splash-scaled.tiff"]];
}

- (void) testCairoImageRendererFullPage
{
   [self assertTrue: [PopplerCairoImageRenderer isSupported]];
   if (![PopplerCairoImageRenderer isSupported])
   {
      return;
   }
   
   PopplerCairoImageRenderer* renderer = 
      [[PopplerCairoImageRenderer alloc] initWithDocument: document];
   [renderer autorelease];
   
   PopplerPage* page = [document page: 1];
   NSBitmapImageRep* imageRep = [renderer renderPage: page scale: 1.0];
   [self assertNotNil: imageRep];
   [self assertInt: [imageRep retainCount] equals: 1];
   [self assertTrue: [self saveAsTIFF: imageRep file: @"cairo-page.tiff"]];
}

- (void) testCairoImageRenderSlice
{
   [self assertTrue: [PopplerCairoImageRenderer isSupported]];
   if (![PopplerCairoImageRenderer isSupported])
   {
      return;
   }

   PopplerCairoImageRenderer* renderer = 
      [[PopplerCairoImageRenderer alloc] initWithDocument: document];
   [renderer autorelease];

   PopplerPage* page = [document page: 1];
   NSRect box;
   box.origin = NSMakePoint(100, 100);
   box.size.width = [page size].width - 100;
   box.size.height = [page size].height - 100;
   
   NSBitmapImageRep* imageRep = [renderer renderPage: page srcBox: box scale: 1.0];
   [self assertNotNil: imageRep];
   [self assertInt: [imageRep retainCount] equals: 1];
   [self assertTrue: [self saveAsTIFF: imageRep file: @"cairo-slice.tiff"]];
}

- (void) testCairoImageRenderScaled
{
   [self assertTrue: [PopplerCairoImageRenderer isSupported]];
   if (![PopplerCairoImageRenderer isSupported])
   {
      return;
   }

   PopplerCairoImageRenderer* renderer = 
      [[PopplerCairoImageRenderer alloc] initWithDocument: document];
   [renderer autorelease];

   PopplerPage* page = [document page: 1];
   NSBitmapImageRep* imageRep = [renderer renderPage: page scale: 0.5];
   [self assertNotNil: imageRep];
   [self assertInt: [imageRep retainCount] equals: 1];
   [self assertTrue: [self saveAsTIFF: imageRep file: @"cairo-scaled.tiff"]];
}

- (BOOL) saveAsTIFF: (NSBitmapImageRep*)bitmap file: (NSString*)aFilename
{
   NSData* tiffData = nil;
   NS_DURING
      tiffData = [bitmap TIFFRepresentation];
   NS_HANDLER
      return NO;
   NS_ENDHANDLER
   
   if (!tiffData || ([tiffData length] == 0))
   {
      return NO;
   }

   NSString* destFile = [kTestRenderDirectory stringByAppendingPathComponent: aFilename];
   return ([tiffData writeToFile: destFile atomically: NO]);
}

@end
