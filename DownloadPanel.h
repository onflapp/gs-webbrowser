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

#ifndef _DOWNLOADPANEL_H_
#define _DOWNLOADPANEL_H_

#import <AppKit/AppKit.h>

@interface DownloadPanel : NSObject
{
  IBOutlet NSTextField* addressField;
  IBOutlet NSTextField* statusField;
  IBOutlet NSButton* openButton;
  IBOutlet NSButton* saveButton;

  IBOutlet NSWindow* window;

  NSURL* downloadURL;
  NSURLConnection* downloadConnection;
  NSString* tempFile;
  NSFileHandle* tempFileHandle;
  NSInteger status;
}

- (id) initWithURL:(NSURL*)url;
- (NSWindow*) window;

- (IBAction) startDownload:(id) sender;
- (IBAction) saveFile:(id) sender;
- (IBAction) openFile:(id) sender;
@end

#endif // _DOWNLOADPANEL_H_

