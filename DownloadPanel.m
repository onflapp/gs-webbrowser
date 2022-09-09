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

#import "DownloadPanel.h"

@implementation DownloadPanel

- (id) initWithURL:(NSURL*)url forWebView:(id)view {
  self = [super init];
  [NSBundle loadNibNamed:@"DownloadPanel" owner:self];

  status = 0;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(parentWindowWillClose:)
                                               name:NSWindowWillCloseNotification
                                             object:[view window]];

  downloadDate = [[NSDate date]retain];
  downloadURL = [url retain];
  downloads = [NSMutableDictionary new];

  [window setTitle:@"Downloading..."];
  [actionButton setHidden:YES];
  [addressField setStringValue:[downloadURL description]];
  [statusField setStringValue:@"waiting for download to start..."];

  [self observerDownloadFolder];
  
  return self;
}

- (void) parentWindowWillClose:(NSNotification*)notification {
  status = -1;
  [window close];
  [self release];
}

- (NSWindow*) window {
  return window;
}

- (IBAction) takeAction:(id) sender {
  NSString* dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
  NSWorkspace* ws = [NSWorkspace sharedWorkspace];
  [ws selectFile:@"." inFileViewerRootedAtPath:dir];
  [window close];
  [self release];
}

- (void) observerDownloadFolder {
  if (status == -1) return;

  NSString* dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDirectoryEnumerator* ls = [fm enumeratorAtPath:dir];
 
  NSString *file;
  while ((file = [ls nextObject])) {
    if ([[ls fileAttributes] objectForKey:@"NSFileType"] == NSFileTypeDirectory) {
      [ls skipDescendents];
    }
    else {
      if ([[file pathExtension] isEqualToString:@"crdownload"] == YES) {
        [statusField setStringValue:@"downloading..."];
      }
      else if (status == 0) {
        NSString* path = [dir stringByAppendingPathComponent:file];
        [downloads setValue:path forKey:file];
      }
      else if ([downloads valueForKey:file] == nil) {
        NSDate* fd = [[ls fileAttributes]objectForKey:@"NSFileCreationDate"];
        if ([fd laterDate:downloadDate]) {
          [window setTitle:@"DONE!"];
          [statusField setStringValue:@"new file has been downloaded"];
          [actionButton setHidden:NO];
          status = -1;
          return;
        }
      }
    }
  }

  if (status == 0) status = 1;
  if (status > 0) {
    [self performSelector:@selector(observerDownloadFolder) withObject:nil afterDelay:1.0];
  }
}

- (void) dealloc {
  NSLog(@"dealloc");
  status = -1;

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [downloadDate release];
  [downloadURL release];
  [downloads release];

  [super dealloc];
}

@end
