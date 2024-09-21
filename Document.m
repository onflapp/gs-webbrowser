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

static NSWindow* _lastMainWindow;

// Function to check URL validity and presence of "https://"
NSInteger checkURLValidity(NSString *urlString) {
  NSString* httpsPattern = @"^https?://";
  NSString* urlPattern = @"^(http://|https://)?([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$";
  NSError* error = nil;

  NSRegularExpression *httpsRegex = [NSRegularExpression regularExpressionWithPattern:httpsPattern
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:&error];

  NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:urlPattern
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&error];

  NSUInteger httpsMatches = [httpsRegex numberOfMatchesInString:urlString
                                                          options:0
                                                            range:NSMakeRange(0, [urlString length])];

  NSUInteger urlMatches = [urlRegex numberOfMatchesInString:urlString
                                                      options:0
                                                        range:NSMakeRange(0, [urlString length])];

  if (httpsMatches > 0) {
    return 2; // URL is fully formed with "https://"
  }
  else if (urlMatches > 0) {
    return 1; // URL is valid but missing "https://"
  }
  else {
    return 0; // Not a valid URL
  }
}


@implementation Document

+ (Document*) lastActiveDocument {
  return (Document*)[_lastMainWindow delegate];
}

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Document" owner:self];
  
  for (NSView* view in [[window contentView] subviews]) {
    if ([view isKindOfClass:[ChromeWebView class]]) {
      webView = (ChromeWebView*)view;
      break;
    }
  }

  [webView setDelegate:self];
  
  return self;
}

- (void) dealloc {
  RELEASE(currentURL);
  [super dealloc];
}

- (NSWindow*) window {
  return window;
}

- (void) showWindow {
  if ([window isVisible]) {
    [window makeKeyAndOrderFront:self];
  }
  else {
    [window setFrameUsingName:@"browser_window"];
    [window setFrameAutosaveName:@"browser_window"];

    if (!_lastMainWindow) _lastMainWindow = [[NSApp orderedWindows] lastObject];
    if (_lastMainWindow) {
      NSRect  r = [_lastMainWindow frame];
      NSPoint p = r.origin;

      p.x += 24;
      [window setFrameOrigin:p];
    }

    [window makeKeyAndOrderFront:self];
  }
}

- (void) goHome:(id) sender {
  NSURL* url = [NSURL URLWithString:[MYConfig valueForKey:@"HOME_ADDRESS"]];

  [self setURL:url];
}

- (void) goBack:(id) sender {
  [webView goBack:sender];
}

- (void) goForward:(id) sender {
  [webView goForward:sender];
}

- (void) saveBookmark:(id) sender {
  NSSavePanel* panel = [NSSavePanel savePanel];
  //[panel setNameFieldStringValue:@"bookmark.url"];

  if ([panel runModal] == NSOKButton) {
    NSString* path = [panel filename];
    NSString* ext  = [path pathExtension];

    if ([ext length] == 0) {
      ext = @"url";
      path = [path stringByAppendingString:@".url"];
    }

    NSData* data = [self provideBookmarkDataForExtension:ext];
    if (data) {
      [data writeToFile:path atomically:NO];
    }
  }
}

- (void) performZoomAction:(id) sender {
  [webView performZoomAction:sender];
}

- (NSString*) currentURL {
  return currentURL;
}

- (void) setURL:(NSURL*) url {
  RELEASE(currentURL);
  currentURL = nil;
  
  if (!url) return;
  
  //[[webView settings] mergeFromDictionary:[MYConfig valueForKey:@"WEBVIEW"]];
  [webView loadURL:url];
  [addressField setStringValue:[url description]];
}

- (void) loadLocation:(id) sender {
  NSString* val = nil;
  NSURL* url = nil;
  
  if ([sender isKindOfClass:[NSTextField class]]) val = [sender stringValue];
  else val = [addressField stringValue];

  NSInteger valid = checkURLValidity(val);
  if (valid == 2) {
     url = [NSURL URLWithString:val];
  }
  else if (valid  == 1) {
     url = [NSURL URLWithString:[@"https://" stringByAppendingString: val]];
  }
  else {
    val = [val stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* search = [NSString stringWithFormat:@"%@%@", [MYConfig valueForKey:@"SEARCH_ADDRESS"], val];
    url = [NSURL URLWithString:search];
  }
  
  //if ([val hasPrefix:@"http://"] || [val hasPrefix:@"https://"] || [val hasPrefix:@"file://"]) {
  //  url = [NSURL URLWithString:val];
  //}
  //else {
  //  val = [val stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  //  NSString* search = [NSString stringWithFormat:@"%@%@", [MYConfig valueForKey:@"SEARCH_ADDRESS"], val];
  //  url = [NSURL URLWithString:search];
  //}
  
  [self setURL:url];
}

- (NSData*) provideBookmarkDataForExtension:(NSString*) ext {
  if (!currentURL) return nil;

  NSMutableString* str = AUTORELEASE([NSMutableString new]);
  [str appendFormat:@"%@\n", currentURL];

  return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*) provideLinkForDragging {
  return currentURL;
}

- (void) windowDidBecomeMain: (NSNotification*)aNotification {
  _lastMainWindow = window;
}

- (void) windowWillClose:(NSNotification *)notification {
  [webView close];

  if (_lastMainWindow == window) _lastMainWindow = nil;

  [window setDelegate: nil];
  [self release];

  if ([MYConfig valueForKey:@"AppHomeURL"] != nil && [[[NSApp delegate] documents] count] == 0) {
    [NSApp terminate:self];
  }
}

- (void) webView:(id)webView didStartLoading:(NSURL*) url {
  [statusField setStringValue:[NSString stringWithFormat:@"loading %@", url]];
}

- (void) webView:(id)webView didFinishLoading:(NSURL*) url {
  [addressField setStringValue:[url description]];
  NSString* host = [url host];
  if (!host) host = @"empty page";
  [statusField setStringValue:[NSString stringWithFormat:@"%@ - loaded", host]];
  
  ASSIGN(currentURL, [url description]);
}

- (void) webView:(id)webView didChangeFullScreen:(BOOL) fullScreen {
  [window setFullScreen:fullScreen];
}

- (void) webView:(id)webView didChangeTitle:(NSString*) title {
  if (title) {
    [window setTitle:title];
  }
  else {
    [window setTitle:@"Unknown"];
  }
}

- (void) webView:(id)webView didChangeStatus:(NSString*) title {
  [statusField setStringValue:title];
}

@end
