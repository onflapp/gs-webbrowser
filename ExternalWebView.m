/*
   Project: WebBrowser

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-04-09 19:44:48 +0200 by oflorian

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

#import "ExternalWebView.h"
#include <netinet/in.h>

@implementation ExternalWebView

- (void) startController {
  int sock, reuse = 1;
  int port = 2222;
  struct sockaddr_in sockaddr;

  buff = [NSMutableString new];

  memset(&sockaddr, 0, sizeof(struct sockaddr_in));
  sockaddr.sin_addr.s_addr = GSSwapHostI32ToBig(INADDR_ANY);
  sockaddr.sin_port = GSSwapHostI16ToBig(port);

  if((sock = socket(AF_INET, SOCK_STREAM, PF_UNSPEC)) == -1) 
    NSLog(@"Unable to create socket - %s\n", strerror(errno));
  else if(setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (char*)&reuse, sizeof(int)) == -1) 
    NSLog(@"Couldn't set reuse on socket - %s\n", strerror(errno));
  else if(bind(sock, (struct sockaddr*)&sockaddr, sizeof(sockaddr)))
    NSLog(@"Couldn't bind to port %d - %s\n", port, strerror(errno));
  else if(listen(sock, 5) == -1)
    NSLog(@"Couldn't listen - %s\n", port, strerror(errno));
  else {
    listener = [[NSFileHandle alloc] initWithFileDescriptor:sock closeOnDealloc:YES];
    [[NSNotificationCenter defaultCenter]
	    addObserver: self
	    selector: @selector(acceptConnection:)
	    name: NSFileHandleConnectionAcceptedNotification
	    object: listener];
    [listener acceptConnectionInBackgroundAndNotify];
  }
}

- (Window) createXWindowID {
  return 0;
}

- (void) sendCommand:(NSString*) cmd {
  NSString* ss = [NSString stringWithFormat:@"%@\n", cmd];
  NSData* data = [ss dataUsingEncoding:NSUTF8StringEncoding];
  [remote writeData:data];
}

- (void) receiveCommand:(NSString*) cmd {
  NSLog(@"command: %@", cmd);
}

- (void) acceptConnection:(id) not {

  if (!remote) [remote release];
  remote = [[not userInfo] objectForKey: NSFileHandleNotificationFileHandleItem];
  [remote retain];
  
  [[NSNotificationCenter defaultCenter]
	    addObserver: self
	    selector: @selector(handleDataOnConnection:)
	    name: NSFileHandleReadCompletionNotification
	    object: remote];

  [remote readInBackgroundAndNotify];
  [listener acceptConnectionInBackgroundAndNotify];
  [self sendCommand:@"HELLO:"];
}

- (void) handleDataOnConnection:(id) not {
  NSData *data = [[not userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([data length] > 0) {
    NSString* ss = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [buff appendString:ss];
    NSLog(@"data: [%@]", buff);
    NSRange r = [buff rangeOfString:@"\n"];
    while (r.location != NSNotFound) {
      NSString* cmd = [buff substringWithRange:NSMakeRange(0, r.location)];
      if ([cmd length] > 0) {
        [self receiveCommand:cmd];
      }
      [buff setString:[buff substringFromIndex:r.location+1]];
      r = [buff rangeOfString:@"\n"];
    }

    [remote readInBackgroundAndNotify];
  }
  else {
    [remote release];
    [buff release];
    buff = nil;
    remote = nil;
  }
}

@end
