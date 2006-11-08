//
//  main.m
//  PreferencesKitExample
//
//  Created by Quentin Mathé on 01/07/05.
//  Copyright __MyCompanyName__ 2005. All rights reserved.
//

#ifdef GNUSTEP
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// FIXME: Hack to workaround the fact Gorm doesn't support NSView as custom view
// class.
@interface CustomView : NSView { }
@end

@implementation CustomView
@end

#else
#import <Cocoa/Cocoa.h>
#endif

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}
