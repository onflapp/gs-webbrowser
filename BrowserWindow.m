/*
   Project: WebBrowser

   Copyright (C) 2022 Free Software Foundation

   Author: ,,,

   Created: 2022-10-12 10:13:28 +0000 by pi

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

#import "BrowserWindow.h"
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <GNUstepGUI/GSDisplayServer.h>

@implementation BrowserWindow
- (BOOL) isFullScreen {
  return fullscreen;
}

- (void) setFullScreen:(BOOL) fullScreenDisplay {
  if (fullScreenDisplay == fullscreen) {
    return;
  }

  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display *)[server serverDevice];
  Window wid = (Window)[self windowRef];
  XEvent xev;

  Atom wm_state = XInternAtom(dpy, "_NET_WM_STATE", True);
  Atom fs = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", True);
  long mask = SubstructureNotifyMask;

  memset(&xev, 0, sizeof(xev));
  xev.type = ClientMessage;
  xev.xclient.display = dpy;
  xev.xclient.window = wid;
  xev.xclient.message_type = wm_state;
  xev.xclient.format = 32;
  xev.xclient.data.l[1] = fs;

  NSView* webView = (NSView*)[[self delegate] webView];
  NSRect r = [webView frame];

  if (fullScreenDisplay) {
    NSLog(@"fullscreen on");
    xev.xclient.data.l[0] = True;
    lastStyle = _styleMask;
    lastFrame = [self frame];
    _styleMask = 0;
    fullscreen = YES;
    lastFrameOffset = [[self contentView] frame].size.height - r.size.height - 5;

    [self setBackgroundColor:[NSColor blackColor]];
    [webView setFrame:NSMakeRect(r.origin.x, r.origin.y, r.size.width, r.size.height + lastFrameOffset)];
  }
  else {
    NSLog(@"fullscreen off");
    xev.xclient.data.l[0] = False;
    _styleMask = lastStyle;
    fullscreen = NO;
    lastFrame.size.width--;

    [self setBackgroundColor:[NSColor windowBackgroundColor]];
    [webView setFrame:NSMakeRect(r.origin.x, r.origin.y, r.size.width, r.size.height - lastFrameOffset)];
    [self setFrame:lastFrame display:YES];
    [self performSelector:@selector(reApplyFrame) withObject:nil afterDelay:0.3];
  }

  if (!XSendEvent(dpy, DefaultRootWindow(dpy), False, mask, &xev)) {
    NSLog(@"Error: sending fullscreen event to xserver");
  }
}

- (void) saveFrameUsingName: (NSString*)name {
  if (fullscreen) return;
  else [super saveFrameUsingName:name];
}

- (void) reApplyFrame {
  lastFrame.size.width++; //hack to force resize
  [self _applyFrame:lastFrame];
  [self display];
}

@end
