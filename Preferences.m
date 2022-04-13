/*
   Project: WebBrowser

   Copyright (C) 2020 Free Software Foundation

   Author: root

   Created: 2020-08-14 19:12:27 +0300 by root

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

#import "Preferences.h"
#import "common.h"

@implementation Preferences
- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"Preferences" owner:self];
  return self;
}

- (void) show:(id) sender {
  [homeAddress setStringValue:[MYConfig valueForKey:@"HOME_ADDRESS"]];
  [searchAddress setStringValue:[MYConfig valueForKey:@"SEARCH_ADDRESS"]];
  [userAgent setStringValue:[MYConfig valueForKeyPath:@"WEBVIEW.USER_AGENT"]];
  [javaScript setIntegerValue:[[MYConfig valueForKeyPath:@"WEBVIEW.JAVASCRIPT"] integerValue]];

  [window makeKeyAndOrderFront:sender];
}

- (void) save:(id) sender {
  [MYConfig setValue:[homeAddress stringValue] forKey:@"HOME_ADDRESS"];
  [MYConfig setValue:[searchAddress stringValue] forKey:@"SEARCH_ADDRESS"];
  
  NSMutableDictionary* webview = [NSMutableDictionary dictionary];
  [webview setValue:[userAgent stringValue] forKey:@"USER_AGENT"];
  [webview setValue:[NSNumber numberWithInteger:[javaScript integerValue]] forKey:@"JAVASCRIPT"];
  
  [MYConfig setValue:webview forKey:@"WEBVIEW"];
}

@end
