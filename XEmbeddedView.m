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
#import <GNUstepGUI/GSDisplayServer.h>
#include "xembed.h"
#include <unistd.h>
#include "X11/Xutil.h"
#include "X11/keysymdef.h"

Display* currentXDisplay() {
  GSDisplayServer *server = GSCurrentServer();
  return (Display *)[server serverDevice];
}

void save_found_wmclass(unsigned char* wmname, unsigned char* wmclass) {
  NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];

  if (wmclass) {
    NSString* str = [[NSString alloc]initWithCString:(const char*)wmclass];
    [cfg setValue:str forKey:@"xembedded_last_wmclass"];
    [str release];
  }

  if (wmname) {
    NSString* str = [[NSString alloc]initWithCString:(const char*)wmname];
    [cfg setValue:str forKey:@"xembedded_last_wmname"];
    [str release];
  }
}

BOOL pointer_over_window(Display* dpy, Window win) {
  Window w;
  Window r;
  int rx, ry, x, y;
  unsigned int m;

  if (XQueryPointer(dpy, win, &r, &w, &rx, &ry, &x, &y, &m)) {
    return YES;
  }
  else return NO;
}

Window find_xwinid_wmclass(Display* dpy, Window rootWindow, const char* wmclass) {
  Window *children;
  Window parent;
  Window root;
  unsigned int nchildren;
  Atom actual_type;
  int actual_format;
  int rv;
  unsigned long nitems;
  unsigned long bytes_after;
  unsigned char *prop_name;
  unsigned char *prop_class;
  XWindowAttributes wattrs;
  XClassHint whints;

  Atom atom_CLASS = XInternAtom(dpy, "WM_CLASS", True);
  Atom atom_NAME = XInternAtom(dpy, "WM_NAME", True);
  
  int result = XQueryTree(dpy, rootWindow, &root, &parent, &children, &nchildren);
  int windowCount = 0;
  Window found = 0;
  
  for (windowCount = nchildren-1; result && windowCount >= 0; windowCount--) {
    Window win = children[windowCount];
    prop_class = NULL;
    prop_name = NULL;

    rv = XGetWindowAttributes(dpy, win, &wattrs);
    if (!rv) {
      continue;
    }
    /*
    if (rv && wattrs.map_state == IsViewable) {
    }
    else {
      continue;
    }
    */

    rv = XGetClassHint(dpy, win, &whints);
    if (rv) {
      if (strcmp(whints.res_class, "GNUstep") == 0) { //skip looking into GNUstep apps
        continue;
      }
      //NSLog(@"NAME >>>> %x %s %s", win, whints.res_name, whints.res_class);
    }

    rv = XGetWindowProperty(dpy, win, atom_CLASS, 0, 1024,
                       False, AnyPropertyType,
                       &actual_type,
                       &actual_format, &nitems,
                       &bytes_after,
                       &prop_class);
                       
    if (rv == Success && prop_class) {
      //NSLog(@"CLASS >>>> %x %s", win, prop_class);
      if (strcmp((const char*)prop_class, wmclass) == 0) {
        found = win;
        save_found_wmclass(NULL, prop_class);
        break;
      }
    }

    rv = XGetWindowProperty(dpy, win, atom_NAME, 0, 1024,
                       False, AnyPropertyType,
                       &actual_type,
                       &actual_format, &nitems,
                       &bytes_after,
                       &prop_name);
                       
    if (rv == Success && prop_name) {
      //NSLog(@"NAME >>>> %x %d %s", win, wattrs.map_state, prop_name);
      if (strcmp((const char*)prop_name, wmclass) == 0) {
        found = win;
        save_found_wmclass(prop_name, prop_class);
        break;
      }
    }

    Window ww = find_xwinid_wmclass(dpy, win, wmclass);
    if (ww > 0) {
      found = ww;
      break;
    }
  }

  if (result && children != NULL) {
    XFree((char*) children);
  }

  return found;
}

@implementation XEmbeddedView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  xwindowid = 0;
  xdisplay = NULL;

  return self;
}

- (void) dealloc {
  NSLog(@"dealloc");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (xwindowid != 0) {
    [self unmapXWindow];
    [self destroyXWindow];
  }

  [super dealloc];
}

- (void) windowWillClose:(NSNotification*) note {
  closingwindow = YES;
  if ([note object] == [self window]) {
    [self destroyXWindow];
  }
}

- (void) viewDidMoveToWindow {
  if ([self window]) {
    isvisible = YES;
    if (xwindowid == 0) {                         
      NSInteger xwinid = [self createXWindowID];
      if (xwinid) {
        [self remapXWindow:xwinid];
      }
    }
  }
  else {
    isvisible = NO;
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
    XFlush(xdisplay);

    xdisplay = NULL;
    xwindowid = 0;
    NSLog(@"DESTROY");
  }
}

- (void) activateXWindow {
  NSWindow* win = [self window];
  if (!win) return;

  if ([NSApp isActive] == NO) {
    [NSApp activateIgnoringOtherApps:YES];
    [win makeKeyAndOrderFront:self];
  }
  else {
    [win makeFirstResponder:self];
    [win makeKeyAndOrderFront:self];
  }
}

- (void) deactivateXWindow:(NSNotification*) note {
  isactive = NO;
}

- (BOOL) acceptsFirstResponder {
  return YES;
}

- (BOOL) becomeFirstResponder {
  if (!isactive) {
    isactive = YES;
  }
  return YES;
}

- (BOOL) resignFirstResponder {
  isactive = NO;
  NSWindow* win = [self window];
  if ([win isKeyWindow]) {
    [GSServerForWindow(win) setinputfocus:[win windowNumber]];
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
  float gsscale = [[NSUserDefaults standardUserDefaults] floatForKey: @"GSScaleFactor"];
  if (gsscale < 0.2) gsscale = 1.0;

  XMoveResizeWindow(xdisplay, xwindowid, r.origin.x * gsscale, r.origin.y * gsscale, r.size.width  * gsscale, r.size.height  * gsscale);
  XFlush(xdisplay);
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

- (void) unmapXWindow {
}

- (Window) findXWindowID:(NSString*) name {
  Display *dpy = currentXDisplay();

  Window rootWindow = XDefaultRootWindow(dpy);
  Window foundWindow = find_xwinid_wmclass(dpy, rootWindow, [name UTF8String]);
  return foundWindow;
}

- (void) initModFilter {
  NSString* cmdkey = [[NSUserDefaults standardUserDefaults] valueForKey:@"GSFirstCommandKey"];
  if ([cmdkey hasPrefix:@"Super_"]) {
    filterModL = XK_Super_L;
    filterModR = XK_Super_R;
    filterMod = Mod4Mask;
  }
  else if ([cmdkey hasPrefix:@"Alt_"]) {
    filterModL = XK_Alt_L;
    filterModR = XK_Alt_L;
    filterMod = Mod1Mask;
  }
  else if ([cmdkey hasPrefix:@"Control_"]) {
    filterModL = XK_Control_L;
    filterModR = XK_Control_R;
    filterMod = ControlMask;
  }
  else if ([cmdkey hasPrefix:@"Meta_"]) {
    filterModL = XK_Meta_L;
    filterModR = XK_Meta_R;
    filterMod = Mod2Mask;
  }
  else {
    filterModL = XK_Alt_L;
    filterModR = XK_Alt_L;
    filterMod = Mod1Mask;
  }
}

- (void) remapXWindow:(Window) xwinid {  
  Window myxwindowid = (Window)[[self window]windowRef];
  xdisplay = currentXDisplay();
  xwindowid = xwinid;
  
  XReparentWindow(xdisplay, xwindowid, myxwindowid, 0, 0);
  XSync(xdisplay, False);
  XMapWindow(xdisplay, xwindowid);

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self 
         selector:@selector(deactivateXWindow:) 
	     name:NSApplicationWillResignActiveNotification
	   object:NSApp];

  [nc addObserver:self 
         selector:@selector(deactivateXWindow:) 
	     name:NSWindowDidResignKeyNotification
	   object:[self window]];

  [nc addObserver:self 
	 selector:@selector(windowWillClose:) 
	     name:NSWindowWillCloseNotification
	   object:[self window]];

  [self initModFilter];

  [self performSelector:@selector(resizeXWindow) withObject:nil afterDelay:0.1];
  [self performSelectorInBackground:@selector(processXWindowsEvents:) withObject:self];
}

- (void) notifyXWindowEventsHasEnded { 
}

- (void) processXWindowsEvents:(id) sender {
  XInitThreads();
  CREATE_AUTORELEASE_POOL(pool);

  Window ws = (Window)[[sender window]windowRef];
  Window we = (Window)[sender embededXWindowID];
  Window wf = None;
  Display *d;
  XEvent e;
  int s;
  int wr;
 
  d = XOpenDisplay(NULL);
  s = DefaultScreen(d);

  Window root = XDefaultRootWindow(d);
  Atom ignore_focus = XInternAtom(d, WM_IGNORE_FOCUS_EVENTS, True);
  XSelectInput(d, we, EnterWindowMask | LeaveWindowMask | StructureNotifyMask);

  BOOL grabbing_mouse = NO;
  BOOL grabbing_keys = NO;

  while (1) {
    XNextEvent(d, &e);

    if (e.type == EnterNotify) {
      XGetInputFocus(d, &wf, &wr);
      if (wf != None && wf != we) {
        NSLog(@"M1 - GRAB");
        XGrabButton(d, AnyButton, AnyModifier, we, 1, ButtonPressMask, GrabModeSync, GrabModeAsync, None, None);
        XGrabKey(d, AnyKey, AnyModifier, we, 1, GrabModeAsync, GrabModeAsync);
        XFlush(d);
        grabbing_mouse = YES;
        grabbing_keys = YES;
      }
    }
    else if (e.type == LeaveNotify) {
      BOOL wf = pointer_over_window(d, we);
      if (grabbing_mouse && wf == NO) {
        NSLog(@"M2 - UN GRAB");
        XUngrabButton(d, AnyButton, AnyModifier, we);
        XUngrabKey(d, AnyKey, AnyModifier, we);
        XFlush(d);
        grabbing_mouse = NO;
      }
    }
    else if (e.type == ButtonPress) {
      if (e.xbutton.button == Button1 || [NSApp isActive]) {
        if (grabbing_mouse) {
          NSLog(@"M3 - UN GRAB");
          XUngrabButton(d, AnyButton, AnyModifier, we);
          XSync(xdisplay, True);
          grabbing_mouse = NO;
        }
        
        if (wf != None && wf != we) {
          usleep(50000);
          [NSApp performSelectorOnMainThread:@selector(disableDeactivation) withObject:nil waitUntilDone:NO];
          [sender performSelectorOnMainThread:@selector(activateXWindow) withObject:nil waitUntilDone:NO];

          //NSLog(@"XSetInputFocus %x", we);
          sendclientmsg(d, root, ignore_focus, 1);
          usleep(50000);
            
          XSetInputFocus(d, we, RevertToParent, CurrentTime);
          XSync(xdisplay, True);

          usleep(50000);
          sendclientmsg(d, root, ignore_focus, 0);

          [NSApp performSelectorOnMainThread:@selector(enableDeactivationAfterDelay) withObject:nil waitUntilDone:NO];
        }
      }
      XAllowEvents(d, ReplayPointer, e.xbutton.time);
    }
    else if (e.type == DestroyNotify) {
      break;
    }
    else if (e.type == KeyPress || e.type == KeyRelease) {
      KeySym keysym = XKeycodeToKeysym(d, e.xkey.keycode, 0);
      //NSLog(@"E %d %d %d %x", e.type, e.xkey.state, e.xkey.keycode, keysym);
      if (e.xkey.state & filterMod) {
        XSendEvent(d, ws, False, NoEventMask, &e);
      }
      else if (keysym == filterModL || keysym == filterModR) {
        XSendEvent(d, ws, False, NoEventMask, &e);
      }
      else if (((XEmbeddedView*)sender)->isactive) {
        XSendEvent(d, we, False, NoEventMask, &e);
      }
      else {
        XSendEvent(d, ws, False, NoEventMask, &e);
      }
      XFlush(d);
    }
  }

  XUngrabButton(d, AnyButton, AnyModifier, we);
  XUngrabKey(d, AnyKey, AnyModifier, we);
  NSLog(@"we are done here");

  xwindowid = 0;
  //XCloseDisplay(d);

  [self performSelectorOnMainThread:@selector(notifyXWindowEventsHasEnded) withObject:nil waitUntilDone:NO];
  RELEASE(pool);
}

@end
