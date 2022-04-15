#import "ChromeWebView.h"
#include <X11/Xlib.h>

@implementation ChromeWebView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];  
  [self connectController];

  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (void) destroyXWindow {
  NSLog(@"destroy");
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
    [self remapXWindow:w];
  }
  if ([nm isEqual:@"ON_FOCUS"]) {
    NSLog(@"focus");
    [[self window] makeFirstResponder:self];
    [[self window] makeKeyAndOrderFront:self];
  }
  if ([nm isEqual:@"ON_LOADING_START"]) {
    [delegate webView:self didStartLoading:[NSURL URLWithString:val]];
  }
  if ([nm isEqual:@"ON_LOADING_STOP"]) {
    [delegate webView:self didFinishLoading:[NSURL URLWithString:val]];
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

  [self sendCommand:[NSString stringWithFormat:@"LOAD:%@", url]];
}

- (id)validRequestorForSendType:(NSString *)st
                     returnType:(NSString *)rt 
{
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
}

- (void) cut:(id)sender {
}

- (void) paste:(id)sender {
}

- (void) selectAll:(id)sender {
}

- (void) undo:(id)sender {
}

- (void) redo:(id)sender {
}

- (void) stopLoading:(id) sender {
}

- (void) goBack:(id) sender {
NSLog(@"back");
  [self sendCommand:@"BACK"];
}

- (void) goForward:(id) sender {
  [self sendCommand:@"FORWARD"];
}

@end
