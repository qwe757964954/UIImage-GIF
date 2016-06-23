//
//  UIImage+YBFGIF.m
//  YiBiFen_CN
//
//  Created by 建星 on 16/4/8.
//  Copyright © 2016年 hhly. All rights reserved.
//

#import "UIImage+YBFGIF.h"
#import <ImageIO/ImageIO.h>
@implementation UIImage (YBFGIF)
+ (UIImage *)sd_animatedGIFNamed:(NSString *)name withDuration:(float)duration
{
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (scale > 1.0f) {
        NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
        
        NSData *data = [NSData dataWithContentsOfFile:retinaPath];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data withDuration:duration];
        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        
        data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data withDuration:duration];
        }
        
        return [UIImage imageNamed:name];
    }
    else {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data withDuration:duration];
        }
        
        return [UIImage imageNamed:name];
    }
    
    
}
+ (UIImage *)sd_animatedGIFWithData:(NSData *)data withDuration:(float)duration
{
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];
        
        //        NSTimeInterval duration = 0.0f;
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            duration += [self sd_frameDurationAtIndex:i source:source];
            
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            
            CGImageRelease(image);
        }
        
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    
    CFRelease(source);
    
    return animatedImage;
}

+ (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}


- (UIImage *)sd_animatedImageByScalingAndCroppingToSize:(CGSize)size {
    if (CGSizeEqualToSize(self.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return self;
    }
    
    CGSize scaledSize = size;
    CGPoint thumbnailPoint = CGPointZero;
    
    CGFloat widthFactor = size.width / self.size.width;
    CGFloat heightFactor = size.height / self.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = self.size.width * scaleFactor;
    scaledSize.height = self.size.height * scaleFactor;
    
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5;
    }
    else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    
    NSMutableArray *scaledImages = [NSMutableArray array];
    
    for (UIImage *image in self.images) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        [scaledImages addObject:newImage];
        
        UIGraphicsEndImageContext();
    }
    
    return [UIImage animatedImageWithImages:scaledImages duration:self.duration];
}

+(void)jx_animated:(UIImageView *)imgView withArrayObject:(NSMutableArray *)array andRepeatCount:(NSInteger)count
{
    
    [imgView setAnimationImages:array];
    [imgView setAnimationRepeatCount:count];
    [imgView setAnimationDuration:8*0.075];
    [imgView startAnimating];
    
}

- (UIImage*)jx_stackBlur:(NSUInteger)inradius
{
    if (inradius < 1){
        return self;
    }
    // Suggestion xidew to prevent crash if size is null
    if (CGSizeEqualToSize(self.size, CGSizeZero)) {
        return self;
    }
    
    //	return [other applyBlendFilter:filterOverlay  other:self context:nil];
    // First get the image into your data buffer
    CGImageRef inImage = self.CGImage;
    size_t nbPerCompt = CGImageGetBitsPerPixel(inImage);
    if (nbPerCompt != 32)
    {
        UIImage *tmpImage = [self normalize];
        inImage = tmpImage.CGImage;
    }
    CFDataRef theData = CGDataProviderCopyData(CGImageGetDataProvider(inImage));
    CFMutableDataRef m_DataRef = CFDataCreateMutableCopy(0, 0, theData);
    CFRelease(theData);
    UInt8 * m_PixelBuf=malloc(CFDataGetLength(m_DataRef));
    CFDataGetBytes(m_DataRef,
                   CFRangeMake(0,CFDataGetLength(m_DataRef)) ,
                   m_PixelBuf);
    
    CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf,
                                             CGImageGetWidth(inImage),
                                             CGImageGetHeight(inImage),
                                             CGImageGetBitsPerComponent(inImage),
                                             CGImageGetBytesPerRow(inImage),
                                             CGImageGetColorSpace(inImage),
                                             CGImageGetBitmapInfo(inImage)
                                             );
    
    // Apply stack blur
    const size_t imageWidth  = CGImageGetWidth(inImage);
    const size_t imageHeight = CGImageGetHeight(inImage);
    [self.class __applyStackBlurToBuffer:m_PixelBuf
                                   width:(int)imageWidth
                                  height:(int)imageHeight
                              withRadius:inradius];
    
    // Make new image
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CFRelease(m_DataRef);
    free(m_PixelBuf);
    
    return finalImage;
}
//获得屏幕图像
+ (UIImage *)imageFromView: (UIView *) theView
{
    
    UIGraphicsBeginImageContext(theView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [theView.layer renderInContext:context];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}
//获得某个范围内的屏幕图像
+ (UIImage *)imageFromView: (UIView *) theView   atFrame:(CGRect)rect
{
    UIGraphicsBeginImageContext(theView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    UIRectClip(rect);
    [theView.layer renderInContext:context];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return  theImage;//[self getImageAreaFromImage:theImage atFrame:r];
}

#pragma mark api

inline static void zeroClearInt(int* p, size_t count) { memset(p, 0, sizeof(int) * count); }
+ (void)__applyStackBlurToBuffer:(UInt8*)targetBuffer
                           width:(const int)w
                          height:(const int)h
                      withRadius:(NSUInteger)inradius
{
    // Constants
    const int radius = (int)inradius; // Transform unsigned into signed for further operations
    const int wm = w - 1;
    const int hm = h - 1;
    const int wh = w*h;
    const int div = radius + radius + 1;
    const int r1 = radius + 1;
    const int divsum = ((div+1)>>1) * ((div+1)>>1);
    
    // Small buffers
    int stack[div*3];
    zeroClearInt(stack, div*3);
    
    int vmin[MAX(w,h)];
    zeroClearInt(vmin, MAX(w,h));
    
    // Large buffers
    int *r = malloc(wh*sizeof(int));
    int *g = malloc(wh*sizeof(int));
    int *b = malloc(wh*sizeof(int));
    zeroClearInt(r, wh);
    zeroClearInt(g, wh);
    zeroClearInt(b, wh);
    
    const size_t dvcount = 256 * divsum;
    int *dv = malloc(sizeof(int) * dvcount);
    for (int i = 0;i < dvcount;i++)
    {
        dv[i] = (i / divsum);
    }
    
    // Variables
    int x, y;
    int *sir;
    int routsum,goutsum,boutsum;
    int rinsum,ginsum,binsum;
    int rsum, gsum, bsum, p, yp;
    int stackpointer;
    int stackstart;
    int rbs;
    
    int yw = 0, yi = 0;
    for (y = 0;y < h;y++)
    {
        rinsum = ginsum = binsum = routsum = goutsum = boutsum = rsum = gsum = bsum = 0;
        
        for (int i = -radius;i <= radius;i++)
        {
            sir = &stack[(i + radius)*3];
            int offset = (yi + MIN(wm, MAX(i, 0)))*4;
            sir[0] = targetBuffer[offset];
            sir[1] = targetBuffer[offset + 1];
            sir[2] = targetBuffer[offset + 2];
            
            rbs = r1 - abs(i);
            rsum += sir[0] * rbs;
            gsum += sir[1] * rbs;
            bsum += sir[2] * rbs;
            if (i > 0)
            {
                rinsum += sir[0];
                ginsum += sir[1];
                binsum += sir[2];
            }
            else
            {
                routsum += sir[0];
                goutsum += sir[1];
                boutsum += sir[2];
            }
        }
        stackpointer = radius;
        
        for (x = 0;x < w;x++)
        {
            r[yi] = dv[rsum];
            g[yi] = dv[gsum];
            b[yi] = dv[bsum];
            
            rsum -= routsum;
            gsum -= goutsum;
            bsum -= boutsum;
            
            stackstart = stackpointer - radius + div;
            sir = &stack[(stackstart % div)*3];
            
            routsum -= sir[0];
            goutsum -= sir[1];
            boutsum -= sir[2];
            
            if (y == 0)
            {
                vmin[x] = MIN(x + radius + 1, wm);
            }
            
            int offset = (yw + vmin[x])*4;
            sir[0] = targetBuffer[offset];
            sir[1] = targetBuffer[offset + 1];
            sir[2] = targetBuffer[offset + 2];
            rinsum += sir[0];
            ginsum += sir[1];
            binsum += sir[2];
            
            rsum += rinsum;
            gsum += ginsum;
            bsum += binsum;
            
            stackpointer = (stackpointer + 1) % div;
            sir = &stack[(stackpointer % div)*3];
            
            routsum += sir[0];
            goutsum += sir[1];
            boutsum += sir[2];
            
            rinsum -= sir[0];
            ginsum -= sir[1];
            binsum -= sir[2];
            
            yi++;
        }
        yw += w;
    }
    
    for (x = 0;x < w;x++)
    {
        rinsum = ginsum = binsum = routsum = goutsum = boutsum = rsum = gsum = bsum = 0;
        yp = -radius*w;
        for(int i = -radius;i <= radius;i++)
        {
            yi = MAX(0, yp) + x;
            
            sir = &stack[(i + radius)*3];
            
            sir[0] = r[yi];
            sir[1] = g[yi];
            sir[2] = b[yi];
            
            rbs = r1 - abs(i);
            
            rsum += r[yi]*rbs;
            gsum += g[yi]*rbs;
            bsum += b[yi]*rbs;
            
            if (i > 0) {
                rinsum += sir[0];
                ginsum += sir[1];
                binsum += sir[2];
            } else {
                routsum += sir[0];
                goutsum += sir[1];
                boutsum += sir[2];
            }
            
            if (i < hm)
            {
                yp += w;
            }
        }
        yi = x;
        stackpointer = radius;
        for (y = 0;y < h;y++)
        {
            int offset = yi*4;
            targetBuffer[offset]     = dv[rsum];
            targetBuffer[offset + 1] = dv[gsum];
            targetBuffer[offset + 2] = dv[bsum];
            rsum -= routsum;
            gsum -= goutsum;
            bsum -= boutsum;
            
            stackstart = stackpointer - radius + div;
            sir = &stack[(stackstart % div)*3];
            
            routsum -= sir[0];
            goutsum -= sir[1];
            boutsum -= sir[2];
            
            if (x == 0)
            {
                vmin[y] = MIN(y + r1, hm)*w;
            }
            p = x + vmin[y];
            
            sir[0] = r[p];
            sir[1] = g[p];
            sir[2] = b[p];
            
            rinsum += sir[0];
            ginsum += sir[1];
            binsum += sir[2];
            
            rsum += rinsum;
            gsum += ginsum;
            bsum += binsum;
            
            stackpointer = (stackpointer + 1) % div;
            sir = &stack[stackpointer*3];
            
            routsum += sir[0];
            goutsum += sir[1];
            boutsum += sir[2];
            
            rinsum -= sir[0];
            ginsum -= sir[1];
            binsum -= sir[2];
            
            yi += w;
        }
    }
    
    free(r);
    free(g);
    free(b);
    free(dv);
}
- (UIImage *)normalize
{
    int width = self.size.width;
    int height = self.size.height;
    CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef thumbBitmapCtxt = CGBitmapContextCreate(NULL,
                                                         width,
                                                         height,
                                                         8, (4 * width),
                                                         genericColorSpace,
                                                         (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(genericColorSpace);
    CGContextSetInterpolationQuality(thumbBitmapCtxt, kCGInterpolationDefault);
    CGRect destRect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(thumbBitmapCtxt, destRect, self.CGImage);
    CGImageRef tmpThumbImage = CGBitmapContextCreateImage(thumbBitmapCtxt);
    CGContextRelease(thumbBitmapCtxt);
    UIImage *result = [UIImage imageWithCGImage:tmpThumbImage];
    CGImageRelease(tmpThumbImage);
    
    return result;
}
@end
