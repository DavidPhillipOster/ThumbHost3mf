//  QOIFImageFromData.m
//  ThumbHost3mf
//
//  Created by david on 12/10/23.
//

#import "QOIFImageFromData.h"

#import <AppKit/AppKit.h>

// BEGIN quote from https://github.com/phoboslab/qoi/blob/master/qoi.h (MIT License)
#include <stdlib.h>
#include <string.h>

#define QOI_SRGB   0
#define QOI_LINEAR 1

typedef struct {
	unsigned int width;
	unsigned int height;
	unsigned char channels;
	unsigned char colorspace;
} qoi_desc;


#ifndef QOI_MALLOC
	#define QOI_MALLOC(sz) malloc(sz)
	#define QOI_FREE(p)    free(p)
#endif
#ifndef QOI_ZEROARR
	#define QOI_ZEROARR(a) memset((a),0,sizeof(a))
#endif

#define QOI_OP_INDEX  0x00 /* 00xxxxxx */
#define QOI_OP_DIFF   0x40 /* 01xxxxxx */
#define QOI_OP_LUMA   0x80 /* 10xxxxxx */
#define QOI_OP_RUN    0xc0 /* 11xxxxxx */
#define QOI_OP_RGB    0xfe /* 11111110 */
#define QOI_OP_RGBA   0xff /* 11111111 */

#define QOI_MASK_2    0xc0 /* 11000000 */

#define QOI_COLOR_HASH(C) (C.rgba.r*3 + C.rgba.g*5 + C.rgba.b*7 + C.rgba.a*11)
#define QOI_MAGIC \
	(((unsigned int)'q') << 24 | ((unsigned int)'o') << 16 | \
	 ((unsigned int)'i') <<  8 | ((unsigned int)'f'))
#define QOI_HEADER_SIZE 14

/* 2GB is the max file size that this implementation can safely handle. We guard
against anything larger than that, assuming the worst case with 5 bytes per
pixel, rounded down to a nice clean value. 400 million pixels ought to be
enough for anybody. */
#define QOI_PIXELS_MAX ((unsigned int)400000000)

typedef union {
	struct { unsigned char r, g, b, a; } rgba;
	unsigned int v;
} qoi_rgba_t;

// Clang falsely claims the variable is used, but I need it to exist to get its size.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused"
static const unsigned char qoi_padding[8] = {0,0,0,0,0,0,0,1};
#pragma clang diagnostic pop

static unsigned int qoi_read_32(const unsigned char *bytes, int *p) {
	unsigned int a = bytes[(*p)++];
	unsigned int b = bytes[(*p)++];
	unsigned int c = bytes[(*p)++];
	unsigned int d = bytes[(*p)++];
	return a << 24 | b << 16 | c << 8 | d;
}

static void *qoi_decode(const void *data, int size, qoi_desc *desc, int channels) {
	const unsigned char *bytes;
	unsigned int header_magic;
	unsigned char *pixels;
	qoi_rgba_t index[64];
	qoi_rgba_t px;
	int px_len, chunks_len, px_pos;
	int p = 0, run = 0;

	if (
		data == NULL || desc == NULL ||
		(channels != 0 && channels != 3 && channels != 4) ||
		size < QOI_HEADER_SIZE + (int)sizeof(qoi_padding)
	) {
		return NULL;
	}

	bytes = (const unsigned char *)data;

	header_magic = qoi_read_32(bytes, &p);
	desc->width = qoi_read_32(bytes, &p);
	desc->height = qoi_read_32(bytes, &p);
	desc->channels = bytes[p++];
	desc->colorspace = bytes[p++];

	if (
		desc->width == 0 || desc->height == 0 ||
		desc->channels < 3 || desc->channels > 4 ||
		desc->colorspace > 1 ||
		header_magic != QOI_MAGIC ||
		desc->height >= QOI_PIXELS_MAX / desc->width
	) {
		return NULL;
	}

	if (channels == 0) {
		channels = desc->channels;
	}

	px_len = desc->width * desc->height * channels;
	pixels = (unsigned char *) QOI_MALLOC(px_len);
	if (!pixels) {
		return NULL;
	}

	QOI_ZEROARR(index);
	px.rgba.r = 0;
	px.rgba.g = 0;
	px.rgba.b = 0;
	px.rgba.a = 255;

	chunks_len = size - (int)sizeof(qoi_padding);
	for (px_pos = 0; px_pos < px_len; px_pos += channels) {
		if (run > 0) {
			run--;
		}
		else if (p < chunks_len) {
			int b1 = bytes[p++];

			if (b1 == QOI_OP_RGB) {
				px.rgba.r = bytes[p++];
				px.rgba.g = bytes[p++];
				px.rgba.b = bytes[p++];
			}
			else if (b1 == QOI_OP_RGBA) {
				px.rgba.r = bytes[p++];
				px.rgba.g = bytes[p++];
				px.rgba.b = bytes[p++];
				px.rgba.a = bytes[p++];
			}
			else if ((b1 & QOI_MASK_2) == QOI_OP_INDEX) {
				px = index[b1];
			}
			else if ((b1 & QOI_MASK_2) == QOI_OP_DIFF) {
				px.rgba.r += ((b1 >> 4) & 0x03) - 2;
				px.rgba.g += ((b1 >> 2) & 0x03) - 2;
				px.rgba.b += ( b1       & 0x03) - 2;
			}
			else if ((b1 & QOI_MASK_2) == QOI_OP_LUMA) {
				int b2 = bytes[p++];
				int vg = (b1 & 0x3f) - 32;
				px.rgba.r += vg - 8 + ((b2 >> 4) & 0x0f);
				px.rgba.g += vg;
				px.rgba.b += vg - 8 +  (b2       & 0x0f);
			}
			else if ((b1 & QOI_MASK_2) == QOI_OP_RUN) {
				run = (b1 & 0x3f);
			}

			index[QOI_COLOR_HASH(px) % 64] = px;
		}

		pixels[px_pos + 0] = px.rgba.r;
		pixels[px_pos + 1] = px.rgba.g;
		pixels[px_pos + 2] = px.rgba.b;
		
		if (channels == 4) {
			pixels[px_pos + 3] = px.rgba.a;
		}
	}

	return pixels;
}
// END quote from https://github.com/phoboslab/qoi/blob/master/qoi.h (MIT License)


/// Given an NSData that contains a QOI image, decode it and return it as a  CGImageRef else nil
/// @param data contains a  QOI image
/// @return a CGImageRef  from the QOI image or nil if failed.
static CGImageRef CreateQOIFCGImageFromData(NSData *data) {
  CGImageRef cgImage = nil;
  if (data.length < 20 || 0 != strncmp((const char *) data.bytes, "qoif", 4)) {
    return cgImage;
  }
  NSUInteger index = 4;
  const char *buffer = (const char *)data.bytes;
  uint32_t width; memcpy(&width, &buffer[index], 4); width = ntohl(width); index += 4;
  uint32_t height; memcpy(&height, &buffer[index], 4); height = ntohl(height); index += 4;
  uint8_t channels; memcpy(&channels, &buffer[index], 1); index += 1;
  uint8_t colorspace; memcpy(&colorspace, &buffer[index], 1); /* index += 1; */

  // sanity check the header
  if (512 < width || 512 < height || 4 < channels || channels < 3 || 1 < colorspace) {
    return cgImage;
  }
  qoi_desc desc;
  // returns a malloc’d block of memory to the pixels. nil on error.
  unsigned char *pixels = qoi_decode(data.bytes, (int)data.length, &desc, channels);
  if (pixels) {
    CGBitmapInfo bitmapInfo = (CGBitmapInfo)(((channels == 4) ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone));
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    // To get this into an NSImage, I copy it into the data of a bitmapimage context. Note that the context might have padding bytes
    // at the end of each row.
    CGContextRef cg = CGBitmapContextCreateWithData(NULL, width, height, 8, 0, space, bitmapInfo, NULL, NULL);
    CGColorSpaceRelease(space);
    if (cg) {
      unsigned char *pixelData = pixels;
      unsigned char *contextData = CGBitmapContextGetData(cg);
      uint32_t rowBytes = (uint32_t)CGBitmapContextGetBytesPerRow(cg);
      for (uint32_t y = 0; y < height; ++y) {
        memcpy(contextData, pixelData, width*channels);
        contextData += rowBytes;
        pixelData += width*channels;
      }
      cgImage = CGBitmapContextCreateImage(cg);
      CGContextRelease(cg);
    }
    free(pixels);
  }
  return cgImage;
}


NSImage *QOIFImageFromData(NSData *data) {
  NSImage *image = nil;
  CGImageRef cgImage = CreateQOIFCGImageFromData(data);
  if (cgImage) {
    image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage))];
    CGImageRelease(cgImage);
  }
  return image;
}
