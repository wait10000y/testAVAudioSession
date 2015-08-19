//
//  ViewController.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "ViewController.h"
#import "AVCaptureManager.h"

//#import "AudioPlayer.h"
//#import "AudioManager.h"
//#import "AudioRecorderTwo.h"

@interface ViewController ()<AVCaptureManagerDelegate>

@property (nonatomic) AVCaptureManager *recorder;
//@property BOOL isCreatedSession;

//@property (nonatomic) AudioPlayer *audioPlayer;
//@property (nonatomic) AudioManager *audioManager;
//@property (nonatomic) AudioRecorderTwo *audioRecorder;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  NSLog(@"------------ ViewController viewDidLoad ---------------");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
  NSLog(@"------- didReceiveMemoryWarning ------");
}

-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
}

-(BOOL)createCaptureSession
{
  if (!self.recorder) {
    self.recorder = [[AVCaptureManager alloc] init];
    self.recorder.delegateVideo = self;
    self.recorder.delegateAudio = self;
    self.recorder.videoOrientation = 1;
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
 */
-(void)toggleVideoOrientation
{
  NSInteger oldOri = self.recorder.videoOrientation;
  NSInteger newOri = 1;
  switch (oldOri) {
    case 1:
      newOri = 4;
      break;
    case 2:
      newOri = 3;
      break;
    case 3:
      newOri = 1;
      break;
    case 4:
      newOri = 2;
      break;
      
    default:
      break;
  }
  if (newOri != oldOri) {
    self.recorder.videoOrientation = newOri;
  }
  
}


#pragma mark === delegate ===
-(void)videoRecordPartData:(UIImage*)theData
{
  [self.imgShow performSelectorOnMainThread:@selector(setImage:) withObject:theData waitUntilDone:NO];
}

-(void)audioRecordPartData:(NSData*)theData
{
  
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
      [self.recorder toggleCamaraInput];
      
    } break;
      
    case 111: // start video
    {
      if (!self.recorder) { [self createCaptureSession]; }
      [self.recorder startRecordVideoWithPreview:self.viewPreview withData:nil isNew:NO];
//      if (self.recorder.previewLayer) {
//        [self.viewPreview.layer addSublayer:self.recorder.previewLayer];
//      }
    } break;
    case 110: // stop video
    {
      [self.recorder stopRecordVideo];
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
      [self.recorder startRecordAudio:nil isNew:NO];
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
