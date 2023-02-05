//
//  GCodeDocument.m
//  3mfQuickLook
//
//  Created by david on 2/4/23.
//

#import "GCodeDocument.h"

#import "ThumbnailGCode.h"

@interface GCodeDocument ()
@property NSImage *thumbnail;
@end

@implementation GCodeDocument

/*
- (NSString *)windowNibName {
    // Override to return the nib file name of the document.
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return <#nibName#>;
}
*/

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return nil.
    // Alternatively, you could remove this method and override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  self.thumbnail = ThumbnailGCode(url);
  if (self.thumbnail) {
    NSWindow *window = [(id)[NSApp delegate] window];
    window.title = url.lastPathComponent;
    NSView *contents = window.contentView;
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(20, 20, 256, 256)];
    imageView.image = self.thumbnail;
    [contents addSubview:imageView];
    return YES;
  }
  if (outError) {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
  }
  return NO;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

@end
