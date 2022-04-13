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

#import "Document.h"
#import "common.h"

@implementation Document
- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];
  [window setFrameAutosaveName:@"browser_window"];
  
  //GORM doesn't make the connection our GTKWebView for some reason
  //so we have to do it manually

  for (NSView* view in [[window contentView] subviews]) {
    if ([view isKindOfClass:[ChromeWebView class]]) {
      webView = view;
      break;
    }
  }

  [webView setDelegate:self];
  
  [window makeKeyAndOrderFront:self];
  return self;
}

- (void) goHome:(id) sender {
  NSURL* url = [NSURL URLWithString:[MYConfig valueForKey:@"HOME_ADDRESS"]];
  
  [self setURL:url];
}

- (void) setURL:(NSURL*) url {
  if (!url) return;
  
  //[[webView settings] mergeFromDictionary:[MYConfig valueForKey:@"WEBVIEW"]];
  [webView loadURL:url];
  [addressField setStringValue:[url description]];
  [window makeFirstResponder:webView];
}

- (void) loadLocation:(id) sender {
  NSString* val = nil;
  NSURL* url = nil;
  
  if ([sender isKindOfClass:[NSTextField class]]) val = [sender stringValue];
  else val = [addressField stringValue];
  
  if ([val hasPrefix:@"http://"] || [val hasPrefix:@"https://"]) {
    url = [NSURL URLWithString:val];
  }
  else {
    val = [val stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* search = [NSString stringWithFormat:@"%@%@", [MYConfig valueForKey:@"SEARCH_ADDRESS"], val];
    url = [NSURL URLWithString:search];
  }
  
  [self setURL:url];
}

- (void) webView:(id)webView didStartLoading:(NSURL*) url {
  [statusField setStringValue:[NSString stringWithFormat:@"loading %@", url]];
}

- (void) webView:(id)webView didFinishLoading:(NSURL*) url {
  [addressField setStringValue:[url description]];
  [statusField setStringValue:[NSString stringWithFormat:@"%@ - loaded", [url host]]];
}

- (void) webView:(id)webView didChangeTitle:(NSString*) title {
  if (title) {
    [window setTitle:title];
  }
  else {
    [window setTitle:@"Unknown"];
  }
}

@end
