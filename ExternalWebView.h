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

#ifndef _WEBVIEW_H_
#define _WEBVIEW_H_

#import <AppKit/AppKit.h>
#import "XEmbeddedView.h"

@interface ExternalWebView : XEmbeddedView
{
  NSFileHandle* listener;
  NSFileHandle* remote;
  NSMutableString* buff;
}

- (void) startController;
- (void) sendCommand:(NSString*) cmd;
@end

#endif // _WEBVIEW_H_

