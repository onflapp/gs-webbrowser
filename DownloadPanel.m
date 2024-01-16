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

- (id) initWithURL:(NSURL*)url {
  self = [super init];
  [NSBundle loadNibNamed:@"DownloadPanel" owner:self];

  status = 0;

  downloadURL = [url retain];

  [openButton setEnabled:NO];
  [saveButton setEnabled:NO];

  [window setTitle:@"Downloading..."];
  [addressField setStringValue:[downloadURL description]];
  [statusField setStringValue:@"waiting for download to start..."];

  NSURLRequest* req = [NSURLRequest requestWithURL:downloadURL];
  downloadConnection = [NSURLConnection connectionWithRequest:req delegate:self];
  [downloadConnection retain];


  return self;
}

- (void) windowWillClose:(NSNotification*)notification {
  status = -1;
  [downloadConnection cancel];

  [window close];
  [self release];
}

- (NSWindow*) window {
  return window;
}

- (NSString*) __suggestName:(NSURLResponse*) resp {
  NSString* fname = [resp suggestedFilename];

  if ([[fname pathExtension] length]) return fname;
  
  NSString* ext = [[resp URL] pathExtension];
  if ([ext length]) return [NSString stringWithFormat:@"%@.%@", fname, ext];

  NSString* mime = [resp MIMEType];
  if ([mime length]) {
    NSRange r = [mime rangeOfString:@"/"];
    if (r.location != NSNotFound) {
      ext = [mime substringFromIndex:r.location+1];
      return [NSString stringWithFormat:@"%@.%@", fname, ext];
    }
  }

  return nil;
}

- (IBAction) openFile:(id) sender {
  NSWorkspace* ws = [NSWorkspace sharedWorkspace];
  
  if ([tempFile hasSuffix:@".tmp"]) {
    NSString* dir = [tempFile stringByDeletingLastPathComponent];
    [ws selectFile:tempFile inFileViewerRootedAtPath:dir];
  }
  else {
    [ws openFile:tempFile];
  }

  [window close];
}

- (IBAction) saveFile:(id) sender {
  NSString* dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
  NSSavePanel* save = [NSSavePanel savePanel];
  NSFileManager* fm = [NSFileManager defaultManager];
  NSWorkspace* ws = [NSWorkspace sharedWorkspace];

  [save setDirectory:dir];

  if ([save runModal]) {
    NSString* fl = [save filename];
    [fm moveItemAtPath:tempFile toPath:fl error:nil];
    [ws selectFile:fl inFileViewerRootedAtPath:dir];

    [window close];
  }
}

- (void) connection:(NSURLConnection*) con didReceiveResponse:(NSURLResponse*) resp {
  NSLog(@"xxxxxxxxx:%@", resp);
  NSString* name = [self __suggestName:resp];
  if (!name) name = @"download.tmp";

  tempFile = [NSString stringWithFormat:@"/tmp/%lx-%@", [self hash], name];
  [tempFile retain];

  [[NSFileManager defaultManager] createFileAtPath:tempFile contents:nil attributes:nil];
  tempFileHandle = [NSFileHandle fileHandleForWritingAtPath:tempFile];
  [tempFileHandle retain];

  [window setTitle:[NSString stringWithFormat:@"downloading: %@...", [tempFile lastPathComponent]]];
}

- (void) connection:(NSURLConnection*) con didReceiveData:(NSData*) data {
  [tempFileHandle writeData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection*) con {
  [tempFileHandle closeFile];

  [window setTitle:[NSString stringWithFormat:@"downloaded: %@", [tempFile lastPathComponent]]];
  [statusField setStringValue:@""];

  [openButton setEnabled:YES];
  [saveButton setEnabled:YES];
}

- (void) dealloc {
  NSLog(@"download dealloc");
  status = -1;

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [downloadURL release];
  [tempFile release];
  [tempFileHandle release];
  [downloadConnection release];

  [super dealloc];
}

@end
