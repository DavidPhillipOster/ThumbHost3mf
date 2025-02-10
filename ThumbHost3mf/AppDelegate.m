//
//  AppDelegate.m
//  3mfQuickLook
//
//  Created by david on 2/4/23.
//

#import "AppDelegate.h"

#import "Thumbnail3MF.h"
#import "ThumbnailGCode.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// Turn an identifier from the build environment into a quoted string.
#define xstr(s) str(s)
#define str(s) #s


@interface AppDelegate ()
@property IBOutlet NSWindow *window;
@property IBOutlet NSImageView *imageView;
@property IBOutlet NSWindow *settingsWindow;
@property IBOutlet NSButton *enableLegendCheckbox;
@property (nonatomic)NSUserDefaults *defaults;
@property NSURL *file;
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
  return YES;
}

- (void)application:(NSApplication *)sender openURLs:(NSArray<NSURL *> *)urls {
  for(NSURL *url in urls){
    [self application:sender openURL:url];
  }
}

- (IBAction)openDocument:(nullable id)sender {
  NSOpenPanel *openPanel = NSOpenPanel.openPanel;
  openPanel.allowsMultipleSelection = YES;
  NSArray<NSString *> *types = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleTypeExtensions"];
  if (@available(macOS 11.0, *)) {
    NSMutableArray<UTType *> *documentTypes = [NSMutableArray array];
    for (NSString *ext in types) {
      UTType *type = [UTType typeWithFilenameExtension:ext];
      if (type) {
        [documentTypes addObject:type];
      }
    }
    openPanel.allowedContentTypes = documentTypes;
  } else {
    openPanel.allowedFileTypes = types;
  }
  [openPanel beginWithCompletionHandler:^(NSModalResponse result) {
    if (result == NSModalResponseOK) {
      [self application:NSApp openURLs:openPanel.URLs];
    }
  }];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  return [self application:sender openURL:[NSURL fileURLWithPath:filename]];
}

- (BOOL)application:(NSApplication *)sender openURL:(NSURL *)url {
  self.file = url;
  NSString *fileExtension = [[url pathExtension] lowercaseString];
  NSImage *thumbnail = nil;
  if ([fileExtension isEqual:@"gcode"] || [fileExtension isEqual:@"bgcode"]) {
    thumbnail = ThumbnailGCode(url);
  } else if ([fileExtension isEqual:@"3mf"]) {
    thumbnail = Thumbnail3MF(url);
  }
  if (thumbnail) {
    NSWindow *window = self.window;
    window.title = url.lastPathComponent;
    self.imageView.image = thumbnail;
    [NSDocumentController.sharedDocumentController noteNewRecentDocumentURL:url];
    [window setRepresentedURL:url];
    return YES;
  }
  return NO;
}

- (NSUserDefaults *)defaults {
  if (nil == _defaults) {
    // the suite name is your developer ID, a period, and your developer prefix, all as an NSString.
    _defaults = [[NSUserDefaults alloc] initWithSuiteName:@"" xstr(SUITE_NAME)];
  }
  return _defaults;
}

- (BOOL)isLegendEnabled{
  return ![self.defaults boolForKey:@"legendDisabled"];
}

- (void)setIsLegendEnabled:(BOOL)isEnabled {
  [self.defaults setBool:!isEnabled forKey:@"legendDisabled"];
  [self.defaults synchronize];
}


- (IBAction)showSettingsPanel:(id)sender {
  if (self.settingsWindow.isVisible) {
    [self.settingsWindow orderOut:self];
  } else {
    self.enableLegendCheckbox.state = self.isLegendEnabled;
    [self.settingsWindow makeKeyAndOrderFront:self];
  }
}

- (IBAction)legendHiddenChanged:(id)sender {
  self.isLegendEnabled = self.enableLegendCheckbox.state == NSControlStateValueOn;
  if (self.file) {
    [self application:sender openURL:self.file];
  }
}

@end
