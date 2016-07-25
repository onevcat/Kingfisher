// WebPImageSerialization.m
//
// Copyright (c) 2014 Mattt Thompson (http://mattt.me/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "WebPImageSerialization.h"

#import <WebP/encode.h>
#import <WebP/decode.h>

NSString * const WebPImageErrorDomain = @"com.webp.image.error";

#define WebPImageDefaultPreset WEBP_PRESET_DEFAULT
#define WebPImagePicturePreset WEBP_PRESET_PICTURE
#define WebPImagePhotoPreset WEBP_PRESET_PHOTO
#define WebPImageDrawingPreset WEBP_PRESET_DRAWING
#define WebPImageIconPreset WEBP_PRESET_ICON
#define WebPImageTextPreset WEBP_PRESET_TEXT

static inline BOOL WebPDataIsValid(NSData *data) {
    if (data && data.length > 0) {
        int width = 0, height = 0;
        return WebPGetInfo(data.bytes, data.length, &width, &height) && width > 0 && height > 0;
    }

    return NO;
}

static NSString * WebPLocalizedDescriptionForVP8StatusCode(VP8StatusCode status) {
    switch (status) {
        case VP8_STATUS_OUT_OF_MEMORY:
            return NSLocalizedStringFromTable(@"VP8 out of memory", @"WebPImageSerialization", nil);
        case VP8_STATUS_INVALID_PARAM:
            return NSLocalizedStringFromTable(@"VP8 invalid parameter", @"WebPImageSerialization", nil);
        case VP8_STATUS_BITSTREAM_ERROR:
            return NSLocalizedStringFromTable(@"VP8 bitstream error", @"WebPImageSerialization", nil);
        case VP8_STATUS_UNSUPPORTED_FEATURE:
            return NSLocalizedStringFromTable(@"VP8 unsupported feature", @"WebPImageSerialization", nil);
        case VP8_STATUS_SUSPENDED:
            return NSLocalizedStringFromTable(@"VP8 suspended", @"WebPImageSerialization", nil);
        case VP8_STATUS_USER_ABORT:
            return NSLocalizedStringFromTable(@"VP8 user Abort", @"WebPImageSerialization", nil);
        case VP8_STATUS_NOT_ENOUGH_DATA:
            return NSLocalizedStringFromTable(@"VP8 not enough data", @"WebPImageSerialization", nil);
        default:
            return NSLocalizedStringFromTable(@"VP8 unknown error", @"WebPImageSerialization", nil);
    }
}

static void WebPFreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

__attribute__((overloadable)) UIImage * UIImageWithWebPData(NSData *data) {
    return UIImageWithWebPData(data, 1.0f, nil);
}

__attribute__((overloadable)) UIImage * UIImageWithWebPData(NSData *data, CGFloat scale, NSError * __autoreleasing *error) {
    NSDictionary *userInfo = nil;

    {
        WebPDecoderConfig config;
        int width = 0, height = 0;

        if(!WebPGetInfo([data bytes], [data length], &width, &height)) {
            userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"WebP header formatting error", @"WebPImageSerialization", nil)};
            goto _error;
        }

        if(!WebPInitDecoderConfig(&config)) {
            userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"WebP image failed to initialize structure", @"WebPImageSerialization", nil)};
            goto _error;
        }

        config.output.colorspace = MODE_RGBA;
        config.options.bypass_filtering = true;
        config.options.no_fancy_upsampling = true;
        config.options.use_threads = true;

        VP8StatusCode status = WebPDecode([data bytes], [data length], &config);
        if (status != VP8_STATUS_OK) {
            userInfo = @{NSLocalizedDescriptionKey: WebPLocalizedDescriptionForVP8StatusCode(status)};
            goto _error;
        }

        size_t bitsPerComponent = 8;
        size_t bitsPerPixel = 32;
        size_t bytesPerRow = 4;
        CGDataProviderRef provider = CGDataProviderCreateWithData(&config, config.output.u.RGBA.rgba, config.options.scaled_width * config.options.scaled_height * bytesPerRow, WebPFreeImageData);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        BOOL shouldInterpolate = YES;

        CGImageRef imageRef = CGImageCreate((size_t)width, (size_t)height, bitsPerComponent, bitsPerPixel, bytesPerRow * width, colorSpace, bitmapInfo, provider, NULL, shouldInterpolate, renderingIntent);

        UIImage *image = [UIImage imageWithCGImage:imageRef];

        CGImageRelease(imageRef);
        CGColorSpaceRelease(colorSpace);
        CGDataProviderRelease(provider);

        return image;
    }
    _error: {
        if (error) {
            *error = [[NSError alloc] initWithDomain:WebPImageErrorDomain code:-1 userInfo:userInfo];
        }

        return nil;
    }
}

extern __attribute__((overloadable)) NSData * UIImageWebPRepresentation(UIImage *image) {
    return UIImageWebPRepresentation(image, (WebPImagePreset)WebPImageDefaultPreset, 75.0f, nil);
}

__attribute__((overloadable)) NSData * UIImageWebPRepresentation(UIImage *image, WebPImagePreset preset, CGFloat quality, NSError * __autoreleasing *error) {
    NSCParameterAssert(quality >= 0.0f && quality <= 100.0f);

    CGImageRef imageRef = image.CGImage;
    NSDictionary *userInfo = nil;

    {
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
        CFDataRef dataRef = CGDataProviderCopyData(dataProvider);

        WebPConfig config;
        WebPPicture picture;

        if (!WebPConfigPreset(&config, (WebPPreset)preset, quality)) {
            userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"WebP image configuration preset initialization failed.", @"WebPImageSerialization", nil)};
            goto _error;
        }

        if (!WebPValidateConfig(&config)) {
            userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"WebP image invalid configuration.", @"WebPImageSerialization", nil)};
            goto _error;
        }

        if (!WebPPictureInit(&picture)) {
            userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"WebP image failed to initialize structure.", @"WebPImageSerialization", nil)};
            goto _error;
        }

        size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);

        picture.colorspace = WEBP_YUV420;
        picture.width = (int)width;
        picture.height = (int)height;

        WebPPictureImportRGBA(&picture, (uint8_t *)CFDataGetBytePtr(dataRef), (int)bytesPerRow);
        WebPPictureARGBToYUVA(&picture, picture.colorspace);
        WebPCleanupTransparentArea(&picture);

        CFRelease(dataRef);

        WebPMemoryWriter writer;
        WebPMemoryWriterInit(&writer);
        picture.writer = WebPMemoryWrite;
        picture.custom_ptr = &writer;
        WebPEncode(&config, &picture);

        NSData *data = [NSData dataWithBytes:writer.mem length:writer.size];
        
        WebPPictureFree(&picture);

        return data;
    }
    _error: {
        if (error) {
            *error = [[NSError alloc] initWithDomain:WebPImageErrorDomain code:-1 userInfo:userInfo];
        }
        
        CFRelease(imageRef);
        
        return nil;
    }
}

@implementation WebPImageSerialization

+ (UIImage *)imageWithData:(NSData *)data
                     error:(NSError * __autoreleasing *)error
{
    return [self imageWithData:data scale:1.0f error:error];
}

+ (UIImage *)imageWithData:(NSData *)data
                     scale:(CGFloat)scale
                     error:(NSError * __autoreleasing *)error
{
    return UIImageWithWebPData(data, scale, error);
}

#pragma mark -

+ (NSData *)dataWithImage:(UIImage *)image
                    error:(NSError * __autoreleasing *)error
{
    return [self dataWithImage:image preset:(WebPImagePreset)WebPImageDefaultPreset quality:1.0f error:error];
}

+ (NSData *)dataWithImage:(UIImage *)image
                   preset:(WebPImagePreset)preset
                  quality:(CGFloat)quality
                    error:(NSError * __autoreleasing *)error
{
    return UIImageWebPRepresentation(image, preset, quality, error);
}

@end

#pragma mark -

#ifndef WEBP_NO_UIIMAGE_INITIALIZER_SWIZZLING
#import <objc/runtime.h>

static inline void webp_swizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@interface UIImage (_WebPImageSerialization)
@end

@implementation UIImage (_WebPImageSerialization)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            webp_swizzleSelector(self, @selector(initWithData:scale:), @selector(webp_initWithData:scale:));
            webp_swizzleSelector(self, @selector(initWithData:), @selector(webp_initWithData:));
            webp_swizzleSelector(self, @selector(initWithContentsOfFile:), @selector(webp_initWithContentsOfFile:));
            webp_swizzleSelector(object_getClass((id)self), @selector(imageNamed:), @selector(webp_imageNamed:));
        }
    });
}

+ (UIImage *)webp_imageNamed:(NSString *)name __attribute__((objc_method_family(new))){
    NSString *path = [[NSBundle mainBundle] pathForResource:[name stringByDeletingPathExtension] ofType:[name pathExtension]];
    if (path) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (WebPDataIsValid(data)) {
            return [WebPImageSerialization imageWithData:data error:nil];
        }
    }

    return [self webp_imageNamed:name];
}

- (id)webp_initWithData:(NSData *)data  __attribute__((objc_method_family(init))) {
    if (WebPDataIsValid(data)) {
        return UIImageWithWebPData(data, 1.0f, nil);
    }

    return [self webp_initWithData:data];
}

- (id)webp_initWithData:(NSData *)data
                  scale:(CGFloat)scale __attribute__((objc_method_family(init)))
{
    if (WebPDataIsValid(data)) {
        return UIImageWithWebPData(data, scale, nil);
    }

    return [self webp_initWithData:data scale:scale];
}

- (id)webp_initWithContentsOfFile:(NSString *)path __attribute__((objc_method_family(init))) {
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (WebPDataIsValid(data)) {
        return UIImageWithWebPData(data, 1.0, nil);
    }

    return [self webp_initWithContentsOfFile:path];
}

@end
#endif
