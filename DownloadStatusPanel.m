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

#import "DownloadStatusPanel.h"

@implementation DownloadStatusPanel

- (id) initWithURL:(NSURL*)url {
  self = [super init];
  [NSBundle loadNibNamed:@"DownloadStatusPanel" owner:self];

  status = 0;

  downloadURL = [url retain];
  downloadDate = [[NSDate date]retain];
  downloads = [NSMutableDictionary new];

  [openButton setEnabled:NO];
  [saveButton setEnabled:NO];

  [window setTitle:@"Downloading..."];
  [addressField setStringValue:[downloadURL description]];
  [statusField setStringValue:@"waiting for download to start..."];

  [self observerDownloadFolder];

  return self;
}

- (void) windowWillClose:(NSNotification*)notification {
  status = -1;

  [window close];
  [self release];
}

- (NSWindow*) window {
  return window;
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
      continue;
    }

    NSDate* fd = [[ls fileAttributes]objectForKey:@"NSFileCreationDate"];

    if ([[file pathExtension] isEqualToString:@"crdownload"] == YES) {
      if ([fd laterDate:downloadDate]) {
        [statusField setStringValue:@"downloading..."];
      }
    }
    else if (status == 0) {
      NSString* path = [dir stringByAppendingPathComponent:file];
      [downloads setValue:path forKey:file];
    }
    else if ([downloads valueForKey:file] == nil) {
      if ([fd laterDate:downloadDate]) {
        ASSIGN(downloadedFile, file);

        [window setTitle:@"File Downloaded"];
        [statusField setStringValue:[NSString stringWithFormat:@"File download: %@", file]];

        [openButton setEnabled:YES];
        [saveButton setEnabled:YES];

        status = -1;
        return;
      }
    }
  }

  if (status == 0) status = 1;
  if (status > 0) {
    [self performSelector:@selector(observerDownloadFolder) withObject:nil afterDelay:1.0];
  }
}

- (IBAction) openFile:(id) sender {
  NSString* dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
  NSWorkspace* ws = [NSWorkspace sharedWorkspace];
  NSString* path = [dir stringByAppendingPathComponent:downloadedFile];

  [ws openFile:path];

  [window close];
}

- (IBAction) saveFile:(id) sender {
  NSString* dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
  NSWorkspace* ws = [NSWorkspace sharedWorkspace];
  NSString* path = [dir stringByAppendingPathComponent:downloadedFile];

  [ws selectFile:path inFileViewerRootedAtPath:dir];

  [window close];
}

- (void) dealloc {
  NSLog(@"download dealloc");
  status = -1;

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [downloadURL release];
  [downloads release];
  [downloadedFile release];

  [super dealloc];
}

@end
