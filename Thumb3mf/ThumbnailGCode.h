//  ThumbnailGCode.h
//
//  Created by David Phillip Oster on 2/4/23.
//
#import <AppKit/AppKit.h>

NSImage *ThumbnailGCode(NSURL *fileURL);

NSImage *ResizeImageWithLegendColor(NSImage *img, CGSize desiredSize, NSString *legend, NSColor *color);
