//  Unzip3MF.h
//  3MFThumb
//
//  Created by david on 2/4/23.
//
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

extern NSString *const Unzip3MFDomain;

enum {
	CANT_READ_AS_ZIP = 10,
	ZIP_NOT_OPEN,
	ZIP_PATH_IS_NIL,
	CANT_LOCATE_SUBFILE,
	CANT_OPEN_SUBFILE,
	CANT_READ_SUBFILE,
};

@interface Unzip3MF : NSObject

/// The path of the zip file.
@property (nonatomic, readonly, copy) NSString *path;

/// The items contained in the zip file. The array of `NSString` objects.
@property (nonatomic, readonly, nullable) NSArray *items;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithZipFile:(NSString *)path error:(NSError * _Nullable *)outErr NS_DESIGNATED_INITIALIZER;
- (nullable NSData *)dataWithContentsOfFile:(NSString *)path error:(NSError * _Nullable *)outErr;

@end

NS_ASSUME_NONNULL_END
