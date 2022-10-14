/*
   Project: WebBrowser

   Copyright (C) 2022 Free Software Foundation

   Author: ,,,

   Created: 2022-10-13 18:29:01 +0000 by pi

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

#import "BrowserApp.h"

@implementation BrowserApp

- (void) deactivate {
   if (ignore_deactivation) {
      NSLog(@"IGNORE DEACTIVATE");
   }
   else {
      NSLog(@"DEACTIVATE");
      [super deactivate];
   }
}

- (void) setIgnoreDeactivation:(BOOL) val {
   ignore_deactivation = val;
}

@end
