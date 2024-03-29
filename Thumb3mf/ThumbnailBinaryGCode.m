//  ThumbnailBinaryGCode.m
//  ThumbHost3mf
//
//  Created by David Phillip Oster on 12/9/23.
//

#import "ThumbnailBinaryGCode.h"

typedef enum ErrorCode {
  noError,
  badHeader,
  badBlockType,
  badCompressionType,
  badCompressSize,
  badChecksum,
  noMoreBlocks,
  badRead,
  badSeek,
} ErrorCode;

// Every block type has a 2 byte parameter field after the block header.
static int ParameterSize = 2;

static ErrorCode ThumbnailBlock(NSUInteger compressedSize, NSData *data, NSUInteger *indexp, NSMutableArray<NSData *> *a){
  if (*indexp + compressedSize <= data.length) {
    const char *buffer = (const char *)data.bytes;
    NSData *imageData = [NSData dataWithBytes:buffer + *indexp length:compressedSize];
    if (imageData) {
      [a addObject:imageData];
    }
    *indexp += compressedSize;
    *indexp += 4; // TODO: why 4 bytes to get to next block?
    return noErr;
  }
  return badRead;
}

static ErrorCode NextBinaryGCodeBlock(NSData *data, NSUInteger *indexp, NSUInteger checkType, NSMutableArray<NSData *> *a){
  if (*indexp + 12 < data.length) { // if remaining bytes to examine could hold a block.
    const char *buffer = (const char *)data.bytes;
    uint16_t blockType; memcpy(&blockType, &buffer[*indexp], 2); *indexp += 2;
    if (!(blockType <= 5)) {
      return badBlockType; // unrecognized block type.
    }
    uint16_t compressionType; memcpy(&compressionType, &buffer[*indexp], 2); *indexp += 2;
    if (!(compressionType <= 3)) {
      return badCompressionType; // unrecognized compression type.
    }
    uint32_t uncompressedSize; memcpy(&uncompressedSize, &buffer[*indexp], 4); *indexp += 4;
    uint32_t compressedSize = uncompressedSize;
    if ((1 <= compressionType && compressionType <= 3)) {
      memcpy(&compressedSize, &buffer[*indexp], 4); *indexp += 4;
      if (data.length <= *indexp) {
        return badCompressSize; // couldn't read compressedSize
      }
    }
#if DEBUG
    fprintf(stderr, "\nbloc:%d compres:%d siz:%d checktype:%d \n", (int)blockType, (int)compressionType, (int)compressedSize, (int)checkType);
#endif
    if (checkType) {
      *indexp += 4; // checksum size.
      if (data.length <= *indexp) {
        return badChecksum; // couldn't read checksum
      }
    }
    *indexp += ParameterSize;
    if (blockType == 5) {
      return ThumbnailBlock(compressedSize, data, indexp, a);
    } else if (blockType < 5) {
      *indexp += compressedSize;
      return data.length <= *indexp ? badSeek : noErr;
    }
  }
  return noMoreBlocks;
}

// given a sufficiently large prefix of a file in memory, extract the binary gcode thumbnails, suitable for NSImage.
NSArray<NSData *> *ThumbnailFromBinaryGCode(NSData *data){
  NSMutableArray<NSData *> *a = [NSMutableArray array];
  if (nil == data || 0 != strncmp((const char *) data.bytes, "GCDE", 4)) {
    return a;
  }
  NSUInteger index = 4;
  const char *buffer = (const char *)data.bytes;

  uint32_t version; memcpy(&version, &buffer[index], 4); index += 4;
  if (1 != version) { // only handles version 1 of the format
    return a;
  }
  uint16_t checktype; memcpy(&checktype, &buffer[index], 2); index += 2;
  if (1 < checktype) { // only handles 0 or 1 as compression enums
    return a;
  }
  while (noError == NextBinaryGCodeBlock(data, &index, checktype, a)) {
  }
  return a;
}


