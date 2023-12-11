//
//  ThumbnailProvider.m
//  3MFThumb
//
//  Created by david on 2/4/23.
//

#import "ThumbnailProvider.h"

#import "ThumbnailGCode.h"
#import "Thumbnail3MF.h"

@implementation ThumbnailProvider

- (void)provideThumbnailForFileRequest:(QLFileThumbnailRequest *)request completionHandler:(void (^)(QLThumbnailReply * _Nullable, NSError * _Nullable))handler {
    
    // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
    
    // First way: Draw the thumbnail into the current context, set up with AppKit's coordinate system.
    handler([QLThumbnailReply replyWithContextSize:request.maximumSize currentContextDrawingBlock:^BOOL {
        NSImage *image = nil;
        NSString *extension = request.fileURL.pathExtension;
        if (NSOrderedSame == [extension caseInsensitiveCompare:@"gcode"] ||
            NSOrderedSame == [extension caseInsensitiveCompare:@"bgcode"]) {
          image = ThumbnailGCode(request.fileURL);
        } else if (NSOrderedSame == [extension caseInsensitiveCompare:@"3mf"]) {
          image = Thumbnail3MF(request.fileURL);
        }
        if (image) {
          [image drawInRect:NSMakeRect(0, 0, request.maximumSize.width, request.maximumSize.height)];
          return YES;
        }
        return NO;
    }], nil);
    
    /*
     
     // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
     handler([QLThumbnailReply replyWithContextSize:request.maximumSize drawingBlock:^BOOL(CGContextRef  _Nonnull context) {
     // Draw the thumbnail here.
     
     // Return YES if the thumbnail was successfully drawn inside this block.
     return YES;
     }], nil);
     
     // Third way: Set an image file URL.
     handler([QLThumbnailReply replyWithImageFileURL:[NSBundle.mainBundle URLForResource:@"fileThumbnail" withExtension:@"jpg"]], nil);
     
     */
}

@end
