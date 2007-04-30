#import "OSBitmapImageNode.h"
#import <EtoileUI/NSImage+NiceScaling.h>

#define MAX_SIZE 128

static NSArray *extensions;

@implementation OSBitmapImageNode

- (NSImage *) preview
{
  if (preview)
    return preview;

  /* Create preview here */
  NSImage *image = [[NSImage alloc] initWithContentsOfFile: [self path]];
  NSSize size = NSZeroSize;
  if (image)
  {
    size = [image size];
    if ((size.width > MAX_SIZE) || (size.height > MAX_SIZE))
    {
      size = NSMakeSize(MAX_SIZE, MAX_SIZE);
      ASSIGN(preview, [image scaledImageToFitSize: size]);
    }
    else
    {
      ASSIGN(preview, image);
    }
    DESTROY(image);
  }

  if (preview == nil)
    ASSIGN(preview, [super preview]);

  return preview;
}

- (BOOL) hasChildren
{
  return NO;
}

- (NSArray *) children
{
  return nil;
}

+ (NSArray *) pathExtension
{
  if (extensions == nil)
  {
    extensions = [[NSArray alloc] initWithObjects: @"tif", @"tiff", @"jpg", @"jpeg", @"png", nil];
  }
  return extensions;
}

@end

