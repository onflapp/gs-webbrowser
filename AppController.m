/* 
   Project: WebBrowser

   Author: onflapp

   Created: 2020-07-22 12:15:43 +0300 by root
   
   Application Controller
*/

#import "AppController.h"
#import "common.h"

@implementation AppController

+ (void) initialize {
  NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
  NSMutableDictionary* webview = [NSMutableDictionary dictionary];
  
  [webview setValue:@"" forKey:@"USER_AGENT"];
  
  [defaults setValue:webview forKey:@"WEBVIEW"];
  [defaults setValue:@"https://www.google.com/search?q=" forKey:@"SEARCH_ADDRESS"];
  [defaults setValue:@"https://github.com/onflapp/gs-desktop" forKey:@"HOME_ADDRESS"];
  
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
  [NSApp setServicesProvider:self];
}

- (BOOL) applicationShouldTerminate:(id)sender {
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
    [doc setURL:url];
  }
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
    Document* doc = [[Document alloc] init];
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

- (void) newDocument: (id)sender {
  Document *doc = [[Document alloc] init];
}

@end
