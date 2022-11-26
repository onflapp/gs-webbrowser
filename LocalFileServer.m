/*
   Project: WebBrowser

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-10-19 16:25:35 +0200 by oflorian

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

#import "LocalFileServer.h"

@implementation LocalFileServer

- (id) init {
  self = [super init];
    
  return self;
}

- (NSInteger) serverPort {
  return [[server socketLocalService]integerValue];
}
- (void) start {
  server = [NSFileHandle fileHandleAsServerAtAddress:@"127.0.0.1" service:@"0" protocol:@"tcp"];


  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self 
         selector:@selector(receiveIncomingConnectionNotification:)     
             name:NSFileHandleConnectionAcceptedNotification object:server];

  NSLog(@"start local server %@", [server socketLocalService]);
  [server acceptConnectionInBackgroundAndNotify];
  [server retain];
}

- (void) receiveIncomingConnectionNotification:(NSNotification*) notification {
  NSLog(@"accept");
  
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSDictionary* info = [notification userInfo];
  NSFileHandle* client = [info objectForKey:NSFileHandleNotificationFileHandleItem];

  [nc addObserver:self 
         selector:@selector(receiveIncomingDataNotification:) 
             name:NSFileHandleDataAvailableNotification object:client];
              
  [client waitForDataInBackgroundAndNotify];
  [client retain];

  [server acceptConnectionInBackgroundAndNotify];
}

- (void) receiveIncomingDataNotification:(NSNotification*) notification {
  NSFileManager* fm = [NSFileManager defaultManager];
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSFileHandle* client = [notification object];
  NSMutableString* head = [[NSMutableString alloc] init];
  NSData* data = [client availableData];
  int nr = 0;

  while ([data length] > 0) {
    const char* bytes = [data bytes];
    for (int i = 0; i < [data length]; i++) {
      char ch = *(bytes+i);
      if (ch == '\n') {
        nr++;
        if (nr == 2) {
          data = nil;
          break;
        }
        [head appendFormat:@"%c", ch];
      }
      else if (ch == '\r') {
      }
      else {
        nr = 0;
        [head appendFormat:@"%c", ch];
      }
    }
    if (!data) break;

    data = [client availableData];
  }

  NSArray* ll = [head componentsSeparatedByString:@" "];
  if ([[ll objectAtIndex:0] isEqualToString:@"GET"]) {
    NSString* path = [ll objectAtIndex:1];

    //we want to reparse the URL to return path only (e.g. the original might include a query string)
    NSURL* uu = [NSURL URLWithString:[NSString stringWithFormat:@"http://dummy:1111%@", path]];
    path = [uu path];

    BOOL isdir = NO;
    BOOL exists = NO;
    exists = [fm fileExistsAtPath:path isDirectory:&isdir];

    if (exists && !isdir) {
      [self writeDataFromFile:path to:client];
    }
    else {
      [self writeError:@"404 Not Found" to:client];
    }
  }
  else {
    [self writeError:@"404 Not Found" to:client];
  }
  [client closeFile];

  //done
  [nc removeObserver:client];
  [client release];
  [head release];

}

- (void) writeError:(NSString*) error to:(NSFileHandle*) client {
  NSMutableString* head = [[NSMutableString alloc] init];
  [head appendFormat:@"HTTP/1.1 %@\r\n", error];
  [head appendString:@"Server: FakeFileServer\r\n"];
  [head appendString:@"Connection: Close\r\n"];
  [head appendString:@"\r\n"];
  
  [client writeData:[head dataUsingEncoding:NSUTF8StringEncoding]];

  [head release];
}

- (void) writeDataFromFile:(NSString*) path to:(NSFileHandle*) client {
  NSString* mime = @"text";
  NSData* data = [[NSData alloc] initWithContentsOfFile:path];

  NSMutableString* head = [[NSMutableString alloc] init];
  [head appendString:@"HTTP/1.1 200 OK\r\n"];
  [head appendString:@"Server: FakeFileServer\r\n"];
  [head appendString:@"Connection: Close\r\n"];
  //[head appendFormat:@"Content-Type: %@\r\n", mime];
  [head appendFormat:@"Content-Length: %lu\r\n", [data length]];
  [head appendString:@"\r\n"];
  
  [client writeData:[head dataUsingEncoding:NSUTF8StringEncoding]];
  [client writeData:data];

  [data release];
  [head release];
}

@end
