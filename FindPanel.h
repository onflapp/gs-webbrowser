#import <AppKit/AppKit.h>

@interface FindPanel : NSObject {
  IBOutlet NSPanel* panel;
  IBOutlet NSTextField* findText;
}

+ (id)sharedInstance;
- (NSString*)findString;

- (void)orderFrontFindPanel:(id)sender;
- (void)performFindPanelAction:(id) sender;

@end
