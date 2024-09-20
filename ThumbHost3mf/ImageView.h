//
//  ImageView.h
//  ThumbHost3mf
//
//  Created by david on 9/19/24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// Allow dropping appropriate .3mf or .gcode files on the imageView.
@interface ImageView : NSImageView <NSDraggingDestination>
@end

NS_ASSUME_NONNULL_END
