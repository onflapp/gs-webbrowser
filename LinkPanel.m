/*
   Project: WebBrowser

   Copyright (C) 2020 Free Software Foundation

   Author: onflapp

   Created: 2020-07-22 12:41:08 +0300 by root

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

#import "LinkPanel.h"

@implementation LinkPanel

- (id)init {
  if (!(self = [super init]))
    return nil;

  return self;
}

static id	sharedLinkPanel = nil;

+ (id) sharedInstance {
  if (!sharedLinkPanel) {
    sharedLinkPanel = [[self alloc] init];
    [NSBundle loadNibNamed:@"LinkPanel" owner:sharedLinkPanel];
  }
  return sharedLinkPanel;
}

- (void) showLinkInfo:(NSURL*)url forWebView:(id)view {
  [webView release];
  webView = [view retain];

  [addressField setStringValue:[url description]];

  NSPoint p = [NSEvent mouseLocation];

  p.y = p.y - [window frame].size.height;
  [window setFrameOrigin:p];
  [window makeKeyAndOrderFront:self];
}

- (IBAction) takeAction:(id) sender {
  if ([sender tag] == 0 && [[webView window]isVisible]) {
    NSURL* url = [NSURL URLWithString:[addressField stringValue]];
    [webView loadURL:url];
  }
  else {
    id del = [NSApp delegate];
    [del application:NSApp openFile:[addressField stringValue]];
  }

  [window performClose:sender];
}

- (void) windowWillClose:(NSNotification*)notification {
  [webView release];
  webView = nil;
}

- (void) dealloc {
  [webView release];

  NSLog(@"dealloc");

  [super dealloc];
}

@end
