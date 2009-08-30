#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#ifdef ETOILEAPP
#import <EtoileUI/EtoileUI.h>
#endif
#import "Controller.h"

int main(int argc, char *argv[])
{
#ifdef ETOILEAPP
    return ETApplicationMain(argc,  (const char **) argv);
#else
    return NSApplicationMain(argc,  (const char **) argv);
#endif
}
