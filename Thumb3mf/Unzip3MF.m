//  Unzip3MF.m
//  3MFThumb
//
//  Created by david on 2/4/23.
//

#import "Unzip3MF.h"

#import "unzip.h"

NSString *const Unzip3MFDomain = @"Unzip3MFDomain";


@interface NSString (OCRUtilities)
- (NSString *)ocr_stringByNormalizingPathForZip;
@end
@implementation NSString (OCRUtilities)

- (NSString *)ocr_stringByNormalizingPathForZip
{
  NSString *normalizingPath = self;
  if(!normalizingPath.absolutePath) {
    normalizingPath = [@"/" stringByAppendingPathComponent:normalizingPath];
  }
  normalizingPath = [normalizingPath stringByStandardizingPath];
  return [normalizingPath substringFromIndex:1];
}

@end

@interface Unzip3MF ()

@property (nonatomic, readwrite, copy) NSString *path;
@property (nonatomic) unzFile unzip;

@end

@implementation Unzip3MF

- (instancetype)initWithZipFile:(NSString *)path  error:(NSError * _Nullable *)outErr {
	self = [super init];
	if(self) {
		self.unzip = unzOpen(path.fileSystemRepresentation);
		if(!self.unzip) {
			if (outErr) {
				*outErr = [NSError errorWithDomain:Unzip3MFDomain code:CANT_READ_AS_ZIP userInfo:@{
					NSLocalizedDescriptionKey : @"Can't open as ZIP"
				}];
			}
			return nil;
		}
		self.path = path;
	}

	return self;
}

- (void)dealloc {
  if(self.unzip) {
    unzClose(self.unzip);
  }
}


#pragma mark -
#pragma mark Accessor Method
- (NSArray *)items {
  if(!self.unzip) {
    NSLog(@"error: the zip file is not opened yet.");
    return nil;
  }

  if(unzGoToFirstFile(self.unzip) != UNZ_OK) {
    NSLog(@"error: cannot go to first file in the zip file.");
    return nil;
  }

  NSMutableArray *items = [NSMutableArray array];
  do {
    char rawFilePath[1024];
    unz_file_info fileInfo;
    if(unzGetCurrentFileInfo(self.unzip, &fileInfo, rawFilePath, sizeof(rawFilePath), NULL, 0, NULL, 0) != UNZ_OK) {
      NSLog(@"error: cannot get current file info.");
      continue;
    }
    NSString *filePath = [NSString stringWithCString:rawFilePath encoding:NSUTF8StringEncoding];
    [items addObject:filePath];
  }
  while(unzGoToNextFile(self.unzip) != UNZ_END_OF_LIST_OF_FILE);

  return items;
}


#pragma mark -
#pragma mark Public Method
- (NSData *)dataWithContentsOfFile:(NSString *)path error:(NSError * _Nullable *)outErr {
  if (!self.unzip) {
		if (outErr) {
			*outErr = [NSError errorWithDomain:Unzip3MFDomain code:ZIP_NOT_OPEN userInfo:@{
				NSLocalizedDescriptionKey : @"zip file is not opened yet"
			}];
		}
    return nil;
  }

  if (!path.length) {
		if (outErr) {
			*outErr = [NSError errorWithDomain:Unzip3MFDomain code:ZIP_PATH_IS_NIL userInfo:@{
				NSLocalizedDescriptionKey : @"zip path is nil."
			}];
		}
    return nil;
  }

  path = [path ocr_stringByNormalizingPathForZip];

  const char *rawFilename = path.UTF8String;
  if(unzLocateFile(self.unzip, rawFilename, 0) != UNZ_OK) {
		if (outErr) {
			NSString *s = [NSString stringWithFormat:@"cannot locate file specified by path '%@'.", path];
			*outErr = [NSError errorWithDomain:Unzip3MFDomain code:CANT_LOCATE_SUBFILE userInfo:@{
				NSLocalizedDescriptionKey : s
			}];
		}
    return nil;
  }

  if(unzOpenCurrentFile(self.unzip) != UNZ_OK) {
		if (outErr) {
			NSString *s = [NSString stringWithFormat:@"cannot open file specified by path '%@'.", path];
			*outErr = [NSError errorWithDomain:Unzip3MFDomain code:CANT_OPEN_SUBFILE userInfo:@{
				NSLocalizedDescriptionKey : s
			}];
		}
    return nil;
  }

  NSMutableData *mutableData = [NSMutableData data];
  unsigned int bufferSize = 1024;
  void *buffer = (void *)malloc(bufferSize);
  while(1) {
    int length = unzReadCurrentFile(self.unzip, buffer, bufferSize);
    if(length == 0) {
      break;
    }
    else if(length < 0) {
			if (outErr) {
				NSString *s = [NSString stringWithFormat:@"error occurred reading data '%d'.", length];
				*outErr = [NSError errorWithDomain:Unzip3MFDomain code:CANT_READ_SUBFILE userInfo:@{
					NSLocalizedDescriptionKey : s
				}];
			}
      unzCloseCurrentFile(self.unzip);
      free(buffer);
      return nil;
    }
    [mutableData appendBytes:buffer length:length];
  }

  unzCloseCurrentFile(self.unzip);
  free(buffer);

  return mutableData;
}

@end
