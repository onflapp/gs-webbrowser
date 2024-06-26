/* 
   Project: WebBrowser

   Author: onflapp

   Created: 2020-07-22 12:15:43 +0300 by root
   
   Application Controller
*/

#import "AppController.h"
#import "common.h"

#import "STScriptingSupport.h"

@implementation AppController

+ (void) initialize {
  NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
  NSMutableDictionary* webview = [NSMutableDictionary dictionary];

  NSString* homeURL = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"AppHomeURL"];
  
  [webview setValue:@"" forKey:@"USER_AGENT"];
  
  [defaults setValue:webview forKey:@"WEBVIEW"];
  [defaults setValue:@"https://www.google.com/search?q=" forKey:@"SEARCH_ADDRESS"];
  [defaults setValue:@"https://github.com/onflapp/gs-desktop" forKey:@"HOME_ADDRESS"];
  [defaults setValue:[NSNumber numberWithInteger:1] forKey:@"SHOW_ON_LAUNCH"];

  if (homeURL) {
    [defaults setValue:homeURL forKey:@"AppHomeURL"];
  }
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init {
  if ((self = [super init])) {
  }
  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) awakeFromNib {
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotif {
  NSUserDefaults* cfg = [NSUserDefaults standardUserDefaults];
  NSString* homeURL = [cfg valueForKey:@"AppHomeURL"];

  [NSApp setServicesProvider:self];

  if([NSApp isScriptingSupported]) {
    [NSApp initializeApplicationScripting];
  }
  
  if ([homeURL length]) {
    NSURL* url = [NSURL URLWithString:homeURL];
    Document* doc = [[Document alloc] init];
    [doc showWindow];
    [doc setURL:url];
  }
}

- (BOOL) applicationShouldTerminate:(id)sender {
  ChromeController* ctrl = [ChromeController sharedInstance];
  [ctrl closeProcess];
  [ctrl release];
  return YES;
}

- (void) applicationWillTerminate:(NSNotification *)aNotif {
}

- (void) searchSelectionService:(NSPasteboard *)pboard
                       userData:(NSString *)userData
                          error:(NSString **)error {
  NSString *text = [[pboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];

  if ([text length] > 0 && [MYConfig valueForKey:@"SEARCH_ADDRESS"]) {
    text = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString* search = [NSString stringWithFormat:@"%@%@", [MYConfig valueForKey:@"SEARCH_ADDRESS"], text];
    NSURL* url = [NSURL URLWithString:search];
    Document* doc = [[Document alloc] init];
    [doc showWindow];
    [doc setURL:url];
  }
}

- (BOOL)application: (NSApplication*)theApp
	          openURL: (NSURL*)url {
    return [self application:NSApp openFile:[url description]];
}

- (void)openURL:(NSPasteboard *)pboard
       userData:(NSString *)userData
          error:(NSString **)error  {
  NSString *path = [[pboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];

  if (path) {
    [self application:NSApp openFile:path];
  }
}

- (void) openDocument: (id)sender {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  [panel setAllowsMultipleSelection: NO];
  [panel setCanChooseDirectories: NO];

  if ([panel runModalForTypes:nil] == NSOKButton) {
    NSString* fileName = [[panel filenames] firstObject];
    [self application:NSApp openFile:fileName];
  }
}

- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName {

  NSURL* url = nil;
  if ([fileName hasPrefix:@"http"] || [fileName hasPrefix:@"file"]) {
    url = [NSURL URLWithString:fileName];
  }
  else if([[fileName pathExtension] isEqualToString:@"url"]) {
    NSString* str = [[NSString stringWithContentsOfFile:fileName] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];
    url = [NSURL URLWithString:str];
  }
  else if ([fileName hasPrefix:@"/"]) {
    url = [NSURL fileURLWithPath:fileName];
  }
  
  if (url) {
    Document* doc = [self documentForURL:url];
    [doc showWindow];
    [doc setURL:url];
  }
  
  return NO;
}

- (void) showPrefPanel: (id)sender {
  if (!preferences) {
    preferences = [[Preferences alloc] init];
  }
  [preferences show:sender];
}

- (void) showDebugWindow: (id)sender {
  ChromeController* ctrl = [ChromeController sharedInstance];
  [ctrl showDebugWindow];
}

- (void) newDocument: (id)sender {
  NSURL *homeURL = [NSURL URLWithString:[MYConfig valueForKey:@"AppHomeURL"]];
  NSURL *url = [NSURL URLWithString:[MYConfig valueForKey:@"HOME_ADDRESS"]];
  NSInteger show = [[MYConfig valueForKey:@"SHOW_ON_LAUNCH"]integerValue];

  Document *doc = [[Document alloc] init];

  if (homeURL) {
    show = YES;
    url = homeURL;
  }

  if (show && url) {
    [doc setURL:url];
  }

  [doc showWindow];
}

- (Document*) documentForURL:(NSURL*) url {
  Document* doc = nil;
  NSString* requestedURL = [url description];

  for (NSWindow* win in [NSApp windows]) {
    if ([[win delegate] isKindOfClass:[Document class]]) {
      doc = (Document*) [win delegate];
      if ([[doc currentURL] isEqualToString: requestedURL]) {
        return doc;
      }
    }
  }

  doc = [[Document alloc] init];
  return doc;
}

@end
