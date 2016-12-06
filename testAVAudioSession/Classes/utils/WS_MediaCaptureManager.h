//
//  WS_MediaCaptureManager.h
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


@interface WS_MediaCaptureManagerVideoProfile : NSObject
@property (nonatomic) NSInteger videoType; // 视频输出类型 1:image
@property (nonatomic) CMTime videoFrameDuration; // 帧率
@property (nonatomic) OSType videoFormat; // 
@property (nonatomic) AVCaptureVideoOrientation videoOrientation; // 设置输出视频默认方向
@property (nonatomic) AVCaptureDevicePosition videoDevicePosition; // 摄像头默认值 AVCaptureDevicePositionFront

@property (nonatomic) CGSize videoSize;   // 视频的尺寸大小
@property (nonatomic) NSString *sessionPreset; // 默认 AVCaptureSessionPresetMedium

-(BOOL)isEqual:(WS_MediaCaptureManagerVideoProfile*)object;
@end

@interface WS_MediaCaptureManagerAudioProfile : NSObject
@property (nonatomic) NSInteger audioChannels;
@property (nonatomic) NSInteger audioSampleRate;
@property (nonatomic) NSInteger audioType;
@property (nonatomic) NSInteger audioDura;

-(BOOL)isEqual:(WS_MediaCaptureManagerAudioProfile*)object;
@end

@protocol WS_MediaCaptureManagerDelegate <NSObject>

@optional
// 音频回调(NSData类型)
-(void)audioRecordPartData:(id)theData withDesc:(CMFormatDescriptionRef)theDesc;
// 视频回调(UIImage类型)
-(void)videoRecordPartData:(id)theData;

  // 全类型的调用: 1:video,0:audio
-(void)managerRecordSampleBuffer:(CMSampleBufferRef *)theBufferRef mediaType:(int)theType;

@end


@class AVCaptureVideoPreviewLayer;
@interface WS_MediaCaptureManager : NSObject
@property (weak, nonatomic) id<WS_MediaCaptureManagerDelegate> delegateVideo; // 视频回调的 delegate
@property (weak, nonatomic) id<WS_MediaCaptureManagerDelegate> delegateAudio; // 音频回调的 delegate

@property (nonatomic,readonly) WS_MediaCaptureManagerVideoProfile *videoProfile; // video 配置
@property (nonatomic,readonly) WS_MediaCaptureManagerAudioProfile *audioProfile; // audio 配置

@property (nonatomic,readonly) AVCaptureVideoOrientation videoOrientation; // 输出视频方向
@property (nonatomic,readonly) AVCaptureDevicePosition videoDevicePosition; // 视频device位置(前置,后置摄像头)
@property (nonatomic,readonly) AVCaptureVideoPreviewLayer *previewLayer; // 视频预览layer


// 开始录音功能
// noErr:正常启动,-1:无法启动session;1:无法启动音频采集;
-(int)startRecordAudio:(WS_MediaCaptureManagerAudioProfile*)theProfile;
// 停止录音功能
-(int)stopRecordAudio;

-(int)startRecordVideo:(WS_MediaCaptureManagerVideoProfile *)theProfile;
-(int)stopRecordVideo;

// 创建AVCaputreSession;
// 开启音频,视频录像时,如果该方法未执行,会自动调用该方法;
-(int)createRecordSession;
// 关闭AVCaputreSession;
// 该方法需要手动调用关闭,停止视频,音频录制时,不会自动执行该方法;
-(int)endRecordSession;


// 设置输出视频默认方向
-(int)changeVideoOrientation:(AVCaptureVideoOrientation)mVideoOrientation;
// 切换视频的镜头
- (int)changeCamaraInput:(AVCaptureDevicePosition)toChangePosition;


@end
