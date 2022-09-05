#import "ChromeWebView.h"
#import "FindPanel.h"
#include <X11/Xlib.h>

@implementation ChromeWebView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];  
  
  chromeController = [[ChromeController alloc]init];
  [chromeController ensureChromeControllerIsReady:self];

  return self;
}

- (void) dealloc {
  [chromeController release];
  chromeController = nil;

  [initialURL release];
  initialURL = nil;

  [super dealloc];
}

- (void) chromeController:(id) controller isReady:(NSFileHandle*) fh {
  [self connectController:fh];
}

- (void) destroyXWindow {
  [chromeController stopTrying];
  [chromeController release];
  chromeController = nil;

  ready = NO;

  [self disconnectController];
  [super destroyXWindow];
}

- (void) receiveCommand:(NSString*) cmd {
  NSRange r = [cmd rangeOfString:@":"];
  NSString* nm = [cmd substringToIndex:r.location];
  NSString* val = [cmd substringFromIndex:r.location+1];
  
  if ([nm isEqual:@"ON_READY"]) {
    NSLog(@"ready: %@", val);
    Window w = [self findXWindowID:val];
    if (w) {
      [self remapXWindow:w];
      ready = YES;

      if (initialURL) {
        [self sendCommand:[NSString stringWithFormat:@"LOAD:%@", initialURL]];
        [initialURL release];
        initialURL = nil;
      }
    }
  }
  if ([nm isEqual:@"ON_FOCUS"]) {
  }
  if ([nm isEqual:@"ON_LOADING_START"]) {
    [delegate webView:self didStartLoading:[NSURL URLWithString:val]];
  }
  if ([nm isEqual:@"ON_LOADING_STOP"]) {
    [delegate webView:self didFinishLoading:[NSURL URLWithString:val]];
  }
  if ([nm isEqual:@"ON_NEW_WINDOW"]) {
    [[NSApp delegate] application:NSApp openFile:val];
  }
}

- (void) setDelegate:(id) del {
  delegate = del;
}

- (id) delegate {
  return delegate;
}

- (void) loadURL:(NSURL*) url {
  if (!url) return;

  if (ready) [self sendCommand:[NSString stringWithFormat:@"LOAD:%@", url]];
  else {
    [initialURL release];
    initialURL = [url retain];
  }
}

- (id)validRequestorForSendType:(NSString *)st
                     returnType:(NSString *)rt {
  if ([st isEqual:NSStringPboardType])
    return self;
  else
    return nil;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pb
                             types:(NSArray *)types
{
  NSString *sel = [[NSPasteboard pasteboardWithName:@"Selection"] stringForType:NSStringPboardType];

  if (sel) {
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pb setString:sel forType:NSStringPboardType];
    return YES;
  }
  else {
    return NO;
  }
}

- (void) copy:(id)sender {
  [self sendCommand:@"COPY"];
}

- (void) cut:(id)sender {
  [self sendCommand:@"CUT"];
}

- (void) paste:(id)sender {
  [self sendCommand:@"PASTE"];
}

- (void) selectAll:(id)sender {
  [self sendCommand:@"SELECTALL"];
}

- (void) undo:(id)sender {
}

- (void) redo:(id)sender {
}

- (void) stopLoading:(id) sender {
}

- (void) goBack:(id) sender {
  [self sendCommand:@"BACK"];
}

- (void) goForward:(id) sender {
  [self sendCommand:@"FORWARD"];
}

- (void) performFindPanelAction:(id) sender {
  FindPanel* panel = [FindPanel sharedInstance];
  if ([sender tag] == 1) {
    [panel orderFrontFindPanel:sender];
  }
  else if ([sender tag] == 2) {
    NSString* text = [panel findString];
    [self sendCommand:[NSString stringWithFormat:@"FINDNEXT:%@", text]];
  }
  else if ([sender tag] == 3) {
    NSString* text = [panel findString];
    [self sendCommand:[NSString stringWithFormat:@"FINDPREV:%@", text]];
  }
}

@end
