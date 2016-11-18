//
//  ViewController.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "ViewController.h"
#import "WS_MediaCaptureManager.h"

//#import "AudioPlayer.h"
//#import "AudioManager.h"
//#import "AudioRecorderTwo.h"







@interface ViewController ()<WS_MediaCaptureManagerDelegate>

@property (nonatomic) WS_MediaCaptureManager *recorder;
@property (nonatomic) WS_VideoPlayer *videoPlayer;

//@property BOOL isCreatedSession;

//@property (nonatomic) AudioPlayer *audioPlayer;
//@property (nonatomic) AudioManager *audioManager;
//@property (nonatomic) AudioRecorderTwo *audioRecorder;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  [self createVideoPlayer];
  NSLog(@"------------ ViewController viewDidLoad ---------------");
}

-(void)createVideoPlayer
{
  if (!self.videoPlayer) {
//    self.videoPlayer = [VideoBuffPlayer new];
    self.videoPlayer = [VideoImagePlayer new];
    self.videoPlayer.frame = self.videoShow.bounds;
    [self.videoShow addSubview:self.videoPlayer];
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
  NSLog(@"------- didReceiveMemoryWarning ------");
}

-(void)actionTimerMethod:(NSTimer *)sender
{
    NSLog(@"--- actionTimerMethod :sender:%@ ---",sender.userInfo);
}


-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  self.videoPlayer.frame = self.videoShow.bounds;
}

-(BOOL)createCaptureSession
{
  if (!self.recorder) {
    self.recorder = [[WS_MediaCaptureManager alloc] init];
    self.recorder.delegateVideo = self;
    self.recorder.delegateAudio = self;
  }
  return [self.recorder createRecordSession];
}


-(BOOL)endCaptureSession
{
  BOOL result = [self.recorder endRecordSession];
  self.imgShow.image = nil;
  self.recorder = nil;
  return result;
}

/*
 2 倒立
 3 右旋90度
 4 左旋90
 1 正
 
 AVCaptureVideoOrientationPortrait           = 1,
 AVCaptureVideoOrientationPortraitUpsideDown = 2,
 AVCaptureVideoOrientationLandscapeRight     = 3,
 AVCaptureVideoOrientationLandscapeLeft      = 4,
 */
-(void)toggleVideoOrientation
{
  NSInteger oldOri = self.recorder.videoOrientation;
  NSInteger newOri = AVCaptureVideoOrientationPortrait;
  switch (oldOri) {
    case AVCaptureVideoOrientationPortrait:
      newOri = AVCaptureVideoOrientationLandscapeLeft;
      break;
    case AVCaptureVideoOrientationPortraitUpsideDown:
      newOri = AVCaptureVideoOrientationLandscapeRight;
      break;
    case AVCaptureVideoOrientationLandscapeRight:
      newOri = AVCaptureVideoOrientationPortrait;
      break;
    case AVCaptureVideoOrientationLandscapeLeft:
      newOri = AVCaptureVideoOrientationPortraitUpsideDown;
      break;
      
    default:
      break;
  }
  if (newOri != oldOri) {
    [self.recorder changeVideoOrientation:newOri];
  }
  
}


#pragma mark === delegate ===
//-(void)videoRecordPartData:(UIImage*)theData
//{
////    NSLog(@"--- image size: %@ , %@",NSStringFromCGSize(theData.size),theData);
//    [self.videoPlayer showImage:theData];
//}
//
//  // delegate
//-(void)audioRecordPartData:(NSData*)theData
//{
//  
//}

-(void)managerRecordSampleBuffer:(CMSampleBufferRef *)theData mediaType:(int)theType
{
  if (theType==1) { // video
    [self.videoPlayer showVideoBuff:theData];
  }
}


- (IBAction)actionOperations:(UIButton *)sender {
  switch (sender.tag) {
    case 100: // create session
    {
      [self createCaptureSession];
      
    } break;
    case 102: // end session
    {
      [self endCaptureSession];
    } break;
      
    case 101: // 切换镜头
    {
      [self.recorder changeCamaraInput:(self.recorder.videoDevicePosition ==AVCaptureDevicePositionFront)?AVCaptureDevicePositionBack:AVCaptureDevicePositionFront];
      
    } break;
      
    case 111: // start video
    {
      if (!self.recorder) { [self createCaptureSession]; }
      [self.recorder startRecordVideo:nil];
      AVCaptureVideoPreviewLayer *previewLayer = self.recorder.previewLayer;
      if (previewLayer) {
        previewLayer.frame = self.viewPreview.layer.bounds;
        [self.viewPreview.layer addSublayer:previewLayer];
      }
    } break;
    case 110: // stop video
    {
      [self.recorder stopRecordVideo];
        [self.viewPreview.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperlayer];
        }];
        self.imgShow.image = nil;
    } break;
    case 121: // start audio
    {
      
//      if (!self.audioRecorder) {
//        self.audioRecorder = [AudioRecorderTwo new];
//        [self.audioRecorder setupAudio];
//      }
//      [self.audioRecorder start];
      
      
//      if (!self.audioManager) {
//        self.audioManager = [AudioManager new];
//      }
//      [self.audioManager begin];
      
//      self.audioPlayer = [AudioPlayer new];
//      [self.audioPlayer startAudioPlayer];

      if (!self.recorder) { [self createCaptureSession]; }
      [self.recorder startRecordAudio:nil];
    } break;
    case 120: // stop audio
    {
//      [self.audioRecorder stop];
      
//      [self.audioManager end];
      
//      [self.audioPlayer stopAudioPlayer];
      
      [self.recorder stopRecordAudio];
    } break;
    case 103: // 切换 视频方向
    {
      [self toggleVideoOrientation];
    } break;
    case 104: // 其他
    {
//      [self endCaptureSession];
    } break;
    default:
      break;
  }
  
}










@end
