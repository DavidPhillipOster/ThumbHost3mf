//  QOIFImageFromData.h
//  ThumbHost3mf
//
//  Created by david on 12/10/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Given an NSData that contains a QOI image, decode it and return it as an NSImage else nil
/// @param data contains a  QOI image
/// @return an NSImage from the QOI image or nil if failed.
NSImage *_Nullable QOIFImageFromData(NSData *data);

NS_ASSUME_NONNULL_END
