#import <AppKit/AppKit.h>
#import "FindPanel.h"

@implementation FindPanel

- (id)init {
  if (!(self = [super init]))
    return nil;

  return self;
}

- (void)loadFindStringFromPasteboard {
  NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];

  if ([[pasteboard types] containsObject:NSStringPboardType]) {
    NSString *string = [pasteboard stringForType:NSStringPboardType];
  }
}

- (void)saveFindStringToPasteboard {
  NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];

  [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
  [pasteboard setString:[self findString] forType:NSStringPboardType];
}

static id	sharedFindPanel = nil;

+ (id)sharedInstance {
  if (!sharedFindPanel) {
    sharedFindPanel = [[self alloc] init];
    [NSBundle loadNibNamed:@"FindPanel" owner:sharedFindPanel];
    //[findPanel setDefaultButtonCell:[findNextButton cell]];
  }
  return sharedFindPanel;
}

- (void) dealloc {
  if (self != sharedFindPanel) {
    [super dealloc];
  }
}

- (NSString*)findString {
  return [findText stringValue];
}

- (void)setFindString:(NSString*)string {
}

- (void)orderFrontFindPanel:(id)sender {
  NSLog(@"order %@", panel);
  [self loadFindStringFromPasteboard];
  [panel makeKeyAndOrderFront:nil];
}

@end
