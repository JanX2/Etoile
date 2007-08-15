/*
 *  Busy
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <Foundation/Foundation.h>
#import <X11/Xlib.h>

static BOOL toggle_response = NO;

int main(int argc, char **argv)
{
	XEvent event;
	Display *dpy = XOpenDisplay(NULL);
	int screen = DefaultScreen(dpy);
	Window root_win = RootWindow(dpy, screen);
	Window win = XCreateSimpleWindow(dpy, root_win, 100, 100, 400, 200, 0, 0, 0xFFFFFF);
	int count = 0;
	Atom X_WM_PROTOCOLS = XInternAtom(dpy, "WM_PROTOCOLS", False);
	Atom X_NET_WM_PING = XInternAtom(dpy, "_NET_WM_PING", False);
	Atom protocols[10];
	protocols[count++] = X_NET_WM_PING;
	XSetWMProtocols(dpy, win, protocols, count);

	XSelectInput(dpy, win, ButtonPressMask | ButtonReleaseMask | StructureNotifyMask);
	XMapWindow(dpy, win);
	while(1)
	{
		XNextEvent(dpy, &event);
		switch(event.type)
		{
			case ButtonPress:
				toggle_response = !toggle_response;
				NSLog(@"Response %d", toggle_response);
				break;
			case ButtonRelease:
				break;
			case ClientMessage:
				if ((event.xclient.data.l[0] == X_NET_WM_PING) &&
					(toggle_response == YES))
				{
					NSLog(@"Response PING");
					event.xclient.window = root_win;
					XSendEvent(dpy, root_win, False,
				        (SubstructureRedirectMask | SubstructureNotifyMask),
						&event);
				}
				break;
		}
	}
}

