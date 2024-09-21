/* 
   Project: WebBrowser

   Author: onflapp

   Created: 2020-07-22 12:15:43 +0300 by root
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import "Document.h"
#import "Preferences.h"

@interface AppController : NSObject
{
  Preferences* preferences;
}

+ (void)  initialize;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

- (void) showPrefPanel: (id)sender;
- (void) newDocument: (id)sender;
- (void) showDebugWindow: (id)sender;
- (Document*) documentForURL:(NSURL*) url;

@end

#endif
