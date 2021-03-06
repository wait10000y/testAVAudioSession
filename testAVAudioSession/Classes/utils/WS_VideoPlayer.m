//
//  WS_VideoPlayer.m
//  testAVAudioSession
//
//  Created by 王士良 on 2016/10/26.
//  Copyright © 2016年 wsliang. All rights reserved.
//

#import "WS_VideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation WS_VideoPlayer

-(void)awakeFromNib
{
  [super awakeFromNib];
  _pause = YES;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _pause = YES;
  }
  return self;
}

-(void)showVideoBuff:(CMSampleBufferRef*)bufferRef
{
  NSLog(@"need implement [showVideoBuff:] method");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end


@implementation VideoBuffPlayer
{
    AVSampleBufferDisplayLayer *bufferPlayLayer;
    
    CVPixelBufferRef previousPixelBuffer;
    bool hasAddObserver;
    
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    bufferPlayLayer = [[AVSampleBufferDisplayLayer alloc] init];
    bufferPlayLayer.frame = self.bounds;
    bufferPlayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    bufferPlayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    bufferPlayLayer.opaque = YES;
    [self.layer addSublayer:bufferPlayLayer];
}


-(void)showVideoBuff:(CMSampleBufferRef *)sampleBuffer
{
  if (self.pause) {
    return;
  }
    if (!sampleBuffer){
        return;
    }
  
//  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(*videoBuffer);
//  
//    @synchronized(self) {
//        if (previousPixelBuffer){
//            CFRelease(previousPixelBuffer);
//            previousPixelBuffer = nil;
//        }
//        previousPixelBuffer = pixelBuffer;
//    }
  
  /**
   创建 CMSampleBufferRef
        //不设置具体时间信息
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
        //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    CFRelease(pixelBuffer);  
    CFRelease(videoInfo);
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
  [bufferPlayLayer enqueueSampleBuffer:sampleBuffer];
//    [bufferPlayLayer enqueueSampleBuffer:sampleBuffer toLayer:sampleBufferDisplayLayer];
    CFRelease(sampleBuffer);
    
    */
    
    if (sampleBuffer){
//        CFRetain(sampleBuffer);
        [bufferPlayLayer enqueueSampleBuffer:*sampleBuffer];
//        CFRelease(sampleBuffer);
        if (bufferPlayLayer.status == AVQueuedSampleBufferRenderingStatusFailed){
            NSLog(@"ERROR: %@", bufferPlayLayer.error);
            if (-11847 == bufferPlayLayer.error.code){
                [self rebuildSampleBufferDisplayLayer];
            }
        }else{
                //            NSLog(@"STATUS: %i", (int)layer.status);
        }
    }else{
        NSLog(@"ignore null samplebuffer");
    }
    
    
}



- (void)rebuildSampleBufferDisplayLayer{
    @synchronized(self) {
        [self teardownSampleBufferDisplayLayer];
        [self setupSampleBufferDisplayLayer];
    }
}

- (void)teardownSampleBufferDisplayLayer
{
    if (bufferPlayLayer){
        [bufferPlayLayer stopRequestingMediaData];
        [bufferPlayLayer removeFromSuperlayer];
        bufferPlayLayer = nil;
    }
}

- (void)setupSampleBufferDisplayLayer{
    if (!bufferPlayLayer){
        bufferPlayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        bufferPlayLayer.frame = self.bounds;
        bufferPlayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        bufferPlayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        bufferPlayLayer.opaque = YES;
        [self.layer addSublayer:bufferPlayLayer];
    }else{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        bufferPlayLayer.frame = self.bounds;
        bufferPlayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [CATransaction commit];
    }
    [self addObserver];
}

- (void)addObserver{
    if (!hasAddObserver){
        NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: self selector:@selector(didResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter addObserver: self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        hasAddObserver = YES;
    }
}

- (void)didResignActive{
    NSLog(@"resign active");
    [self setupPlayerBackgroundImage];
}

- (void) setupPlayerBackgroundImage{
  @synchronized(self) {
    if (previousPixelBuffer){
      UIImage *image = [self getUIImageFromPixelBuffer:previousPixelBuffer];
      CFRelease(previousPixelBuffer);
      
      previousPixelBuffer = nil;
    }
  }
}

- (UIImage*)getUIImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    UIImage *uiImage = nil;
    if (pixelBuffer){
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        uiImage = [UIImage imageWithCIImage:ciImage];
        UIGraphicsBeginImageContext(self.bounds.size);
        [uiImage drawInRect:self.bounds];
        uiImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return uiImage;
}

-(void)dealloc
{
    if (hasAddObserver) {
        hasAddObserver = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    if (bufferPlayLayer) {
        [bufferPlayLayer flushAndRemoveImage];
        [bufferPlayLayer stopRequestingMediaData];
    }
}

-(void)pause:(BOOL)isPause
{
  NSLog(@"need implement [pause:] method");
}

-(void)stop
{
  NSLog(@"need implement [stop] method");
}

@end



@implementation VideoImagePlayer
{
    UIImage *tempImage;
    UIImage *newImage;
    
    CADisplayLink *display;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    [self setDefaultData];
  }
  return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
  [self setDefaultData];
}

-(void)setDefaultData
{
  display = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCall:)];
  [display addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void)displayLinkCall:(id)sender
{
  if (self.pause) {
    return;
  }
  NSLog(@" CADisplayLink needDisplayImage ");
    if (newImage != tempImage) {
        [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
//      self.layer.contents = (__bridge id _Nullable)(newImage.CGImage);
//      tempImage = newImage;
    }
}

-(void)showVideoBuff:(CMSampleBufferRef *)bufferRef
{
  if (self.pause) {
    return;
  }
  UIImage *image = [self imageFromSampleBuffer:bufferRef videoFormat:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
  [self showImage:image];
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef *) sampleBuffer videoFormat:(OSType)videoFormat
{
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(*sampleBuffer);
    // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  NSDictionary *opt =  @{ (id)kCVPixelBufferPixelFormatTypeKey : @(videoFormat) };
  CIImage *image = [[CIImage alloc]   initWithCVPixelBuffer:imageBuffer options:opt];
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//  return [UIImage imageWithCIImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
  return [UIImage imageWithCIImage:image];
  
}

-(void)showImage:(UIImage*)theImage
{
  if (self.pause) {
    return;
  }
  newImage = theImage;

//    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (newImage) {
        NSLog(@"--- VideoShowView drawRect image:%@ ,drawFrame:%@ ---",tempImage,NSStringFromCGRect(rect));
            //        CGContextRef context = UIGraphicsGetCurrentContext();
            //        CGFloat contextScale = [UIScreen mainScreen].scale;
            //        UIGraphicsBeginImageContextWithOptions(drawFrame.size, NO, contextScale);
            //        CGContextDrawImage(context, drawFrame, newImage.CGImage);

      CGRect drawFrame = rect;
      if (CGSizeEqualToSize(newImage.size,self.bounds.size)) {
        drawFrame = self.bounds;
      }else{
        CGSize imgSize = newImage.size;
        CGSize osize = self.bounds.size;
        float oWidth = 0;
        float oHeight = 0;

        float OriRad = imgSize.height/imgSize.width;
        float NewRad = osize.height/osize.width;

        if (OriRad < NewRad) {
          oWidth = osize.width;
          oHeight = OriRad*osize.width;
        }else{
          oHeight = osize.height;
          oWidth = osize.height/OriRad;
        }
        drawFrame = CGRectMake((osize.width-oWidth)/2, (osize.height-oHeight)/2, oWidth, oHeight);
      }

        [newImage drawInRect:drawFrame];
    }
    tempImage = newImage;

}

- (void)dealloc
{
    [display invalidate];
  display = nil;
}

@end





@implementation VideoImageLayerPlayer

-(void)showVideoBuff:(CMSampleBufferRef *)bufferRef
{
  if (self.pause) {
    return;
  }
  @autoreleasepool {
    UIImage *image = [self imageFromSampleBuffer:bufferRef videoFormat:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    if (image) {
      CGImageRef cgImage = image.CGImage;
      if (image.CGImage == NULL) {
        static CIContext *context = nil;
        if (!context) {
          context = [CIContext contextWithOptions:nil];
        }
        cgImage = [context createCGImage:image.CIImage fromRect:[image.CIImage extent]];
      }
      [self.layer performSelectorOnMainThread:@selector(setContents:) withObject:(__bridge id)(cgImage) waitUntilDone:NO];
      CGImageRelease(cgImage);
    }

  }

}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef *) sampleBuffer videoFormat:(OSType)videoFormat
{
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(*sampleBuffer);
    // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  NSDictionary *opt =  @{ (id)kCVPixelBufferPixelFormatTypeKey : @(videoFormat) };
  CIImage *ciImage = [[CIImage alloc]   initWithCVPixelBuffer:imageBuffer options:opt];
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//  CVPixelBufferRelease(imageBuffer);
    //  return [UIImage imageWithCIImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
  return [UIImage imageWithCIImage:ciImage];


//  CIContext *context = [CIContext contextWithOptions:nil];
//  CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
//  [filter setValue:ciImage forKey:kCIInputImageKey];
//  [filter setValue:@0.8f forKey:kCIInputIntensityKey];
//  CIImage *outputImg = [filter outputImage];
//  CGImageRef cgImage = [context createCGImage:outputImg fromRect:[outputImg extent]];
//  
//  return cgImage;

}




-(void)showImage:(UIImage*)theImage
{
  if (self.pause) {
    return;
  }
//  self.layer.contents = (__bridge id _Nullable)(theImage.CGImage);
[self.layer performSelectorOnMainThread:@selector(setContents:) withObject:(__bridge id _Nullable)(theImage.CGImage) waitUntilDone:NO];

}

@end


@interface VideoShowLayer : CALayer
  //AVSampleBufferDisplayLayer

-(void)playImage:(UIImage*)theImage;

@end

@implementation VideoShowLayer
{
  UIImage *tempImage;
}

-(void)playImage:(UIImage *)theImage
{
  if (theImage != tempImage) {
    tempImage = theImage;
    [self setNeedsDisplay];
  }
}

- (void)drawInContext:(CGContextRef)ctx
{
  [super drawInContext:ctx];
  
  CGContextSaveGState(ctx);
  
  if (tempImage) {
    CGContextDrawImage(ctx, self.bounds, tempImage.CGImage);
    CGContextRestoreGState(ctx);
  }
  
}

@end
