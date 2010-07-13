/**
 * Étoilé ProjectManager - XCBConnection.h
 *
 * Copyright (C) 2009 David Chisnall
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

#import "XCBNotifications.h"

extern NSString* XCBConnectionEstablishmentException;

@class XCBWindow;
@class XCBVisual;

@interface XCBConnection : NSObject {
	xcb_connection_t *connection;
	NSFileHandle *handle;
	NSMutableArray *screens;
	NSMutableArray *replyHandlers;
	NSMapTable *windows;
	id delegate;
	BOOL needsFlush;
	SEL extensionSelectors[256];
	xcb_timestamp_t currentTime;
}
+ (XCBConnection*)sharedConnection;
- (xcb_connection_t*)connection;
- (void)setDelegate: (id)aDelegate;
- (id)delegate;
- (void)setSelector: (SEL)aSelector forXEvent: (uint8_t)anEvent;
- (NSArray*)screens;
- (XCBWindow*)windowForXCBId: (xcb_window_t)anId;
- (void)registerWindow: (XCBWindow*)aWindow;
- (void)unregisterWindow: (XCBWindow*)aWindow;
- (void)setHandler: (id)anObject 
          forReply: (unsigned int)sequence
          selector: (SEL)aSelector;
- (void)setHandler: (id)anObject
          forReply: (unsigned int)sequence
          selector: (SEL)aSelector
            object: (id)context;
- (void)setHandler: (id)anObject
          forReply: (unsigned int)sequence
          selector: (SEL)aSelector
            object: (id)context
     errorSelector: (SEL)errorSelector;
- (void)cancelHandlersForObject: (id)anObject;
- (void)grab;
- (void)ungrab;
- (void)setNeedsFlush: (BOOL)shouldFlush;
- (BOOL)needsFlush;
- (void)startMessageLoop;
- (xcb_timestamp_t)currentTime;
- (void)allowEvents: (xcb_allow_t)allow timestamp: (xcb_timestamp_t)time;
@end

@interface NSObject (XCBConnectionDelegate)
- (void)finishedProcessingEvents: (XCBConnection*)connection;
@end

/**
 * Shared global XCB connection.  Only one connection may exist per process.
 * This variable is invalid before the first call to XCBConnection
 * +sharedConnection.
 */
extern XCBConnection *XCBConn;
