//  Thumbnail3MF.m
//  3MFThumb
//
//  Created by david on 2/4/23.
//

#import "Thumbnail3MF.h"

#import "ThumbnailGCode.h"
#import "Unzip3MF.h"

NSImage *Thumbnail3MF(NSURL *fileURL) {
  NSError *error = nil;
  Unzip3MF *unzip = [[Unzip3MF alloc] initWithZipFile:fileURL.path error:&error];
  if (unzip) {
    NSData *thumbData = [unzip dataWithContentsOfFile:@"Metadata/thumbnail.png" error:&error];
    if (nil == thumbData) {
      thumbData = [unzip dataWithContentsOfFile:@"Metadata/thumbnail.jpg" error:&error];
    }
    if (thumbData) {
      NSImage *image = [[NSImage alloc] initWithData:thumbData];
      if (image) {
        image = ResizeImageWithLegendColor(image, image.size, @"3MF", [NSColor colorWithRed:0.2 green:1 blue:0.2  alpha:0.5]);
      }
      return image;
    }
  }

  return nil;
}
