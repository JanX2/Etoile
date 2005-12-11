#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <PreferencesKit/PreferencesKit.h>

// FIXME: Hack to workaround the fact Gorm doesn't support NSView as custom view
// class.
@interface CustomView : NSView { }
@end

@implementation CustomView
@end


int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}
