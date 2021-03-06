/*
   Project: WebBrowser

   Copyright (C) 2020 Free Software Foundation

   Author: root

   Created: 2020-08-08 14:25:54 +0300 by root

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "XEmbeddedView.h"
#include "xembed.h"

Window find_xwinid_wmclass(Display* dpy, Window rootWindow, char* wmclass) {
    Window *children;
    Window parent;
    Window root;
    unsigned int nchildren;
    Atom actual_type;
    int actual_format;
    int rv;
    unsigned long nitems;
    unsigned long bytes_after;
    unsigned char *prop;

    //Atom atom_PID = XInternAtom(dpy, "_NET_WM_PID", True);
    Atom atom_CLASS = XInternAtom(dpy, "WM_CLASS", True);
    Atom atom_NAME = XInternAtom(dpy, "WM_NAME", True);
    
    int result = XQueryTree(dpy, rootWindow, &root, &parent, &children, &nchildren);
    unsigned int windowCount = 0;
    for (windowCount = 0; result && windowCount < nchildren; windowCount++) {
        Window win = children[windowCount];
      
        /*  
        NSInteger pid = 0;
        rv = XGetWindowProperty(dpy, win, atom_PID, 0, 1024,
                           False, AnyPropertyType,
                           &actual_type,
                           &actual_format, &nitems,
                           &bytes_after,
                           &prop);
        if (rv != Success) continue;
        if (!prop) continue;
        
        pid = prop[0] + (prop[1]<<8) + (prop[2]<<16) + (prop[3]<<24);
        */

        rv = XGetWindowProperty(dpy, win, atom_CLASS, 0, 1024,
                           False, AnyPropertyType,
                           &actual_type,
                           &actual_format, &nitems,
                           &bytes_after,
                           &prop);
                           
        if (rv == Success && prop) {
          NSLog(@">>>> %x %s", win, prop);
          if (strcmp(prop, wmclass) == 0) return win;
        }

        rv = XGetWindowProperty(dpy, win, atom_NAME, 0, 1024,
                           False, AnyPropertyType,
                           &actual_type,
                           &actual_format, &nitems,
                           &bytes_after,
                           &prop);
                           
        if (rv == Success && prop) {
          NSLog(@">>>> %x %s", win, prop);
          if (strcmp(prop, wmclass) == 0) return win;
        }

        Window ww = find_xwinid_wmclass(dpy, win, wmclass);
        if (ww > 0) return ww;   
    }
    if (result && children != NULL) {
        XFree((char*) children);
    }

    return 0;
}

@implementation XEmbeddedView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  xwindowid = 0;
  xdisplay = NULL;

  /*
  [[NSNotificationCenter defaultCenter] addObserver:self 
					   selector:@selector(deactivateXWindow:) 
					  name:NSWindowDidResignKeyNotification
					object:[self window]];
*/				       
  [[NSNotificationCenter defaultCenter] addObserver:self 
					   selector:@selector(windowWillClose:) 
					  name:NSWindowWillCloseNotification
					object:[self window]];

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (xwindowid != 0) {
    [self unmapXWindow];
    [self destroyXWindow];
  }

  [super dealloc];
}

- (void) processXWindowsEvents:(id) sender {
  Window ws = (Window)[[sender window]windowRef];
  Window we = (Window)[sender embededXWindowID];
  Display *d;
  XEvent e;
  int s;
 
  d = XOpenDisplay(NULL);
  s = DefaultScreen(d);

  //w = XCreateSimpleWindow(d, ws, 0, 0, 100, 100, 1, BlackPixel(d, s), WhitePixel(d, s));
  //XSelectInput(d, w, ExposureMask | KeyPressMask | ButtonPressMask);
  //XMapWindow(d, w);

  NSLog(@"start");
  XGrabButton(d, AnyButton, AnyModifier, we, 1, ButtonPressMask | ButtonReleaseMask, GrabModeAsync, GrabModeAsync, None, None);
  XGrabKeyboard(d, ws, 1, GrabModeAsync, GrabModeAsync, CurrentTime);
  XSync(d, True);

  while (1) {
    XNextEvent(d, &e);
    NSLog(@"e");
    if (e.type == Expose) {
    }
    if (e.type == ButtonPress || e.type == ButtonRelease) {
      [sender performSelectorOnMainThread:@selector(activateXWindow) withObject:nil waitUntilDone:NO];
      XSendEvent(d, we, False, NoEventMask, &e);
      XFlush(d);
      NSLog(@"m");
    }
    if (e.type == KeyPress || e.type == KeyRelease) {
      XSendEvent(d, ws, False, NoEventMask, &e);
      XFlush(d);
    }
  }
 
  XUngrabKeyboard(d, CurrentTime);
  XUngrabButton(d, AnyButton, AnyModifier, we);
  XCloseDisplay(d);
  NSLog(@"end");
}

- (void) windowWillClose:(NSNotification*) note {
  if ([note object] == [self window]) {
    [self destroyXWindow];
  }
}

- (void) viewDidMoveToWindow {
  if ([self window]) {
    if (xwindowid == 0) {                         
      NSInteger xwinid = [self createXWindowID];
      if (xwinid) {
        [self remapXWindow:xwinid];
      }
    }
  }
  else {
    if (xwindowid != 0) {
      [self unmapXWindow];
      [self destroyXWindow];
    }
  }
}

- (Window) createXWindowID {
  return 0;
}

- (void) destroyXWindow {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (xdisplay && xwindowid) {
    XDestroyWindow(xdisplay, xwindowid);
    XSync(xdisplay, True);
    xdisplay = NULL;
    xwindowid = 0;
  }
}

- (void) activateXWindow {
  NSWindow* win = [self window];
  if (!win) return;

  [win makeKeyAndOrderFront:self];  
  [win makeFirstResponder:self];
  
  if ([NSApp isActive] == NO) {
    [NSApp activateIgnoringOtherApps:YES];
  }
}

- (void) deactivateXWindow {
  [self resignFirstResponder];
}

- (BOOL) acceptsFirstResponder {
    return YES;
}

- (void) xxx {
  //Window myxwindowid = (Window)[[self window]windowRef];
//XSetInputFocus(xdisplay, xwindowid, RevertToNone, CurrentTime);
//XFlush(xdisplay);
}

- (BOOL) becomeFirstResponder {
  if (xdisplay && xwindowid) {
    sendxembed(xdisplay, xwindowid, XEMBED_FOCUS_IN, XEMBED_FOCUS_CURRENT, 0, 0);
    sendxembed(xdisplay, xwindowid, XEMBED_WINDOW_ACTIVATE, 0, 0, 0);
    XFlush(xdisplay);
  }
  return YES;
}

- (BOOL) resignFirstResponder {
  if (xdisplay && xwindowid) {
    sendxembed(xdisplay, xwindowid, XEMBED_FOCUS_OUT, XEMBED_FOCUS_CURRENT, 0, 0);
    sendxembed(xdisplay, xwindowid, XEMBED_WINDOW_DEACTIVATE, 0, 0, 0);
    XFlush(xdisplay);
  }
  return YES;
}

- (void) resizeWithOldSuperviewSize:(NSSize) sz {
  [super resizeWithOldSuperviewSize:sz];
  [self resizeXWindow];
}

- (void) resizeXWindow {
  if (!xwindowid || !xdisplay) return;
  if (![self window]) return;

  XMapWindow(xdisplay, xwindowid); 
  
  NSRect r = [self convertToNativeWindowRect];
  
  XMoveResizeWindow(xdisplay, xwindowid, r.origin.x, r.origin.y, r.size.width, r.size.height);
  XFlush(xdisplay);
  NSLog(@"resized");
}

- (Window) embededXWindowID {
  return xwindowid;
}

- (NSRect) convertToNativeWindowRect {
  NSRect r = [self bounds];
  NSView* sv = [self superview];
  while (sv) {
    NSRect sr = [sv bounds];
    r.origin.x += sr.origin.x;
    r.origin.y += sr.origin.y;
    sv = [sv superview];
  }
  NSInteger x = (NSInteger)r.origin.x;
  NSInteger y = (NSInteger)r.origin.y;
  NSInteger w = (NSInteger)r.size.width;
  NSInteger h = (NSInteger)r.size.height;
  
  y = [[[self window] contentView] bounds].size.height - r.size.height - r.origin.y;

  return NSMakeRect(x, y, w, h);
}

/*
- (void) drawRect:(NSRect)r {
  [[NSColor redColor] setFill];
  NSRectFill(r);
}
*/

- (void) unmapXWindow {
}

- (void) remapXWindow:(Window) xwinid {  
  Window myxwindowid = (Window)[[self window]windowRef];
  xdisplay = XOpenDisplay(NULL);
  xwindowid = xwinid;
  
  XReparentWindow(xdisplay, xwindowid, myxwindowid, 0, 0);
  XSync(xdisplay, False);
  XMapWindow(xdisplay, xwindowid);
  
  NSLog(@"mmmm %x - %x:", xwindowid, myxwindowid);
  
  [self performSelector:@selector(resizeXWindow) withObject:nil afterDelay:0.1];
  //[self performSelectorInBackground:@selector(processXWindowsEvents:) withObject:self];
}

- (Window) findXWindowID:(NSString*) name {
  Display* dpy = XOpenDisplay(NULL);
  Window rootWindow = XDefaultRootWindow(dpy);
  Window foundWindow = find_xwinid_wmclass(dpy, rootWindow, [name UTF8String]);
  return foundWindow;
}

@end
