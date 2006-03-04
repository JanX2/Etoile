
#import <AppKit/NSImage.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSString.h>

static inline NSImage *
FindImageInBundleOfClass (Class owner, NSString * imageName)
{
  return [[[NSImage alloc]
    initByReferencingFile: [[NSBundle bundleForClass: owner]
    pathForResource: imageName ofType: @"tiff"]]
    autorelease];
}

static inline NSImage *
FindImageInBundle (id owner, NSString * imageName)
{
  return FindImageInBundleOfClass ([owner class], imageName);
}
