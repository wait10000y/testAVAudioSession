//
//  AVCaptureManager.h
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

/*
 
 录制的命令工作全部切换到该线程操作:
 dispatch_sync(_sessionQueue, ^{});
 
 */

/*
 typedef NS_ENUM(NSInteger, AVCaptureVideoOrientation) {
 AVCaptureVideoOrientationPortrait           = 1,
 AVCaptureVideoOrientationPortraitUpsideDown = 2,
 AVCaptureVideoOrientationLandscapeRight     = 3,
 AVCaptureVideoOrientationLandscapeLeft      = 4,
 }
 */


/*
 
 NSString *const AVEncoderAudioQualityKey;
 NSString *const AVEncoderBitRateKey;
 NSString *const AVEncoderBitRatePerChannelKey;
 NSString *const AVEncoderBitRateStrategyKey;
 NSString *const AVEncoderBitDepthHintKey;
 
 
 
 */







#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

struct AVCaptureManagerRecordStatus {
  int sessionCreate:1;
  int sessionStart:1;
  int sessionEnd:1;
  
  int videoCreate:1;
  int videoStarted:1;
  int videoStop:1;
  int videoRelease:1;
  
  int audioCreate:1;
  int audioStarted:1;
  int audioStop:1;
  int audioRelease:1;
};


@protocol AVCaptureManagerDelegate <NSObject>

@optional
-(void)audioRecordPartData:(id)theData withDesc:(CMFormatDescriptionRef)theDesc;
-(void)videoRecordPartData:(id)theData;

@end


@class AVCaptureVideoPreviewLayer;
@interface AVCaptureManager : NSObject
@property (weak, nonatomic) id<AVCaptureManagerDelegate> delegateVideo;
@property (weak, nonatomic) id<AVCaptureManagerDelegate> delegateAudio;

@property (nonatomic) NSInteger videoOrientation;
@property (nonatomic,readonly) struct AVCaptureManagerRecordStatus status;

@property (nonatomic,readonly) AVCaptureVideoPreviewLayer *previewLayer;


-(BOOL)startRecordAudio:(id)theData isNew:(BOOL)isNew;
-(BOOL)stopRecordAudio;
-(BOOL)startRecordVideoWithPreview:(UIView*)theView withData:(id)theData isNew:(BOOL)isNew;
-(BOOL)stopRecordVideo;

-(BOOL)createRecordSession;
-(BOOL)endRecordSession;


- (NSInteger)toggleCamaraInput;


@end
