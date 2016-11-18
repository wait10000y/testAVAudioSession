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

-(void)showVideoBuff:(CMSampleBufferRef*)bufferRef
{
  NSLog(@"need implement this method");
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

@end


@implementation VideoImagePlayer
{
    UIImage *tempImage;
    UIImage *newImage;
    CGRect drawFrame;
    
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
}

-(void)setDefaultData
{
  display = [CADisplayLink displayLinkWithTarget:self selector:@selector(needDisplayImage:)];
  [display addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void)needDisplayImage:(id)sender
{
    if (newImage != tempImage) {
        NSLog(@" CADisplayLink needDisplayImage ");
        [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
    }
}

-(void)showVideoBuff:(CMSampleBufferRef *)bufferRef
{
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
  return [UIImage imageWithCIImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
  
}

-(void)showImage:(UIImage*)theImage
{
    drawFrame = self.bounds;
        //    if (theImage) {
        //        CGSize imgSize = theImage.size;
        //        CGSize osize = self.frame.size;
        //        float oWidth = 0;
        //        float oHeight = 0;
        //
        //        float OriRad = theImage.size.height/theImage.size.width;
        //        float NewRad = osize.height/osize.width;
        //
        //
        //
        //        if((OriRad>=1 && NewRad <=1) ||(OriRad<= 1 && NewRad >=1)){
        //            osize = CGSizeMake(osize.height, osize.width);
        //        }
        //
        //        if((osize.width>=oriSize.width && osize.height>=oriSize.height) ||(osize.width>=oriSize.height && osize.height>=oriSize.width)){
        //            osize = oriSize;
        //        }else{
        //            if (OriRad < NewRad) {
        //                osize.height = OriRad*osize.width;
        //            }else{
        //                osize.width = osize.height/OriRad;
        //            }
        //        }
        //        drawFrame = CGRectMake(abs(self.frame.size.width-osize.width)/2, abs(self.frame.size.height-osize.height)/2, osize.width, osize.height);
        //
        //    }
    newImage = theImage;
        //    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (newImage) {
        NSLog(@"--- VideoShowView drawRect image:%@ ,drawFrame:%@ ---",tempImage,NSStringFromCGRect(drawFrame));
            //        CGContextRef context = UIGraphicsGetCurrentContext();
            //        CGFloat contextScale = [UIScreen mainScreen].scale;
            //        UIGraphicsBeginImageContextWithOptions(drawFrame.size, NO, contextScale);
            //        CGContextDrawImage(context, drawFrame, newImage.CGImage);
        [newImage drawInRect:drawFrame];
    }
    tempImage = newImage;
    
}

- (void)dealloc
{
    [display invalidate];
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
