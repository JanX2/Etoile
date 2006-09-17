
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <PopplerKit/PopplerKit.h>
#import <ObjcUnit/ObjcUnit.h>

@interface PopplerRendererTest : TestCase {
   PopplerDocument* document;
}

- (BOOL) saveAsTIFF: (NSBitmapImageRep*)bitmap file: (NSString*)aFilename;

@end
