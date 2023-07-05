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

#ifndef _DOCUMENT_H_
#define _DOCUMENT_H_

#import <AppKit/AppKit.h>
#import "ChromeWebView.h"

@interface Document : NSObject
{
  IBOutlet NSWindow *window;
  IBOutlet ChromeWebView* webView;
  IBOutlet NSTextField* addressField;
  IBOutlet NSTextField* statusField;
  
  NSString* currentURL;
}

+ (Document*) lastActiveDocument;

- (NSWindow*) window;

- (void) loadLocation:(id) sender;
- (void) goBack:(id) sender;
- (void) goForward:(id) sender;
- (void) saveBookmark:(id) sender;

- (NSData*) provideBookmarkDataForExtension:(NSString*) ext;
- (NSString*) provideLinkForDragging;

- (NSString*) currentURL;
- (void) setURL:(NSURL*) url;
- (void) showWindow;

@end

#endif // _DOCUMENT_H_

