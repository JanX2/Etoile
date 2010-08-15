/**
 * Étoilé ProjectManager - XCBDamage.h
 *
 * Copyright (C) 2010 Christopher Armstrong <carmstrong@fastmail.com.au>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import <Foundation/Foundation.h>
#include <xcb/xcb.h>
#include <xcb/damage.h>
#import <XCBKit/XCBNotifications.h>
#import <XCBKit/XCBDrawable.h>

@class XCBConnection;
@class XCBFixesRegion;

@interface XCBDamage : NSObject
{
	xcb_damage_damage_t damage;
}

/**
  * Initialise the extension for the connection, and register any
  * event handlers that exist on the delegate.
  */
+ (void)initializeExtensionWithConnection: (XCBConnection*)connection;

- (id) initWithDrawable: (NSObject<XCBDrawable>*)drawable
            reportLevel: (xcb_damage_report_level_t)reportLevel;
+ (XCBDamage*) damageWithDrawable: (NSObject<XCBDrawable>*)drawable
                      reportLevel: (xcb_damage_report_level_t)reportLevel;
- (xcb_damage_damage_t) xcbDamageId;
/**
  * Damage Subtract operation
  *
  * There are two parameters, both of which may be nil
  * This method (I think) causes the damage extension to subtract the
  * regions you propose to repair and gives you back the region that 
  * you should repaint. Effectively, if we're interpreting the spec correctly:
  * if (repair == None)
  *   repair = a region covering the whole drawable
  * tmp = damage INTERSECT repair (i.e. where the repair and damage overlap)
  * damage = damage - tmp (remove the overlap from damage)
  * if (parts != None)
  *   parts = tmp
  * generate DamageNotify for remaining damage regions.
  * If repair is None, it will just assume you want to repair all the damage
  */
- (void)subtractWithRepair: (XCBFixesRegion*)repair 
                     parts: (XCBFixesRegion*)parts;
@end

extern NSString* XCBWindowDamageNotifyNotification;

/**
  * A callback interface for damage notify events. Implement
  * this on the delegate of an XCBWindow to receive for damage
  * notify events on that window
  */
@interface NSObject (XCBDamageDelegate)
- (void)xcbWindowDamageNotify: (NSNotification*)notification;
@end
