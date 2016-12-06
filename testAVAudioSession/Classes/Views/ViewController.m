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

#import "testShowImageView.h"





@interface ViewController ()<WS_MediaCaptureManagerDelegate>

@property (nonatomic) WS_MediaCaptureManager *recorder;
@property (nonatomic) WS_VideoPlayer *videoPlayer;

//@property BOOL isCreatedSession;

//@property (nonatomic) AudioPlayer *audioPlayer;
//@property (nonatomic) AudioManager *audioManager;
//@property (nonatomic) AudioRecorderTwo *audioRecorder;

@property (nonatomic) UIImage *testImage;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  [self createVideoPlayer];
  NSLog(@"------------ ViewController viewDidLoad ---------------");

  _testImage = [UIImage imageNamed:@"test2"];
  NSLog(@"-----iamge:%@ ----",_testImage);

}

-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
//  [self testImageShow];
  [self testSortString];
  self.videoPlayer.frame = self.videoShow.bounds;
  [self.videoShow addSubview:self.videoPlayer];
}


-(void)testSortString
{
  NSArray *sortedArr = @[
                         @"2016-11-08 12",
                         @"2017-11-07 12",
                         @"2016-11-09 13",
                         @"2016-11-09 12",
                         ];

sortedArr = [sortedArr sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {

  NSComparisonResult result = [obj1 compare:obj2];
  NSLog(@"--- obj1:%@ , obj2:%@ compare result:%d ",obj1,obj2,result);
  return  [obj1 compare:obj2];
}];

  NSLog(@"----arr:%@ ======",sortedArr);
}


-(void)testImageShow
{
//  CALayer *newLayer = [[CALayer alloc] init];
//  newLayer.frame = self.view.layer.frame;
//  [self.view.layer addSublayer:newLayer];
  testShowImageView *tView = [[testShowImageView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:tView];
  [tView.layer setBackgroundColor:[UIColor cyanColor].CGColor];

  int fps = 40;
  uint32_t sleepTime = 1000000.0f/fps;
  NSLog(@"----- 设置 图片 刷新率:%d -----",fps);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    long index = 0;
    do {
      usleep(sleepTime);
      UIImage *testImage = [UIImage imageNamed:[NSString stringWithFormat:@"test%ld",(++index)%3]];
//      [tView performSelectorOnMainThread:@selector(showImage:) withObject:testImage waitUntilDone:NO];
      [tView performSelectorOnMainThread:@selector(showImageInLayer:) withObject:testImage waitUntilDone:NO];

    } while (YES);

  });


}

-(void)createVideoPlayer
{
  if (!self.videoPlayer) {
//    self.videoPlayer = [VideoBuffPlayer new];
    self.videoPlayer = [[VideoImageLayerPlayer alloc] init];
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
  [self.videoPlayer setPause:YES];
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
      /**
       @property (nonatomic) NSInteger videoType; // 视频输出类型:image
       @property (nonatomic) CMTime videoFrameDuration; // 帧率
       @property (nonatomic) OSType videoFormat; //
       @property (nonatomic) AVCaptureVideoOrientation videoOrientation; // 设置输出视频默认方向
       @property (nonatomic) AVCaptureDevicePosition videoDevicePosition; // 摄像头默认值 AVCaptureDevicePositionFront

       @property (nonatomic) CGSize videoSize;   // 视频的尺寸大小
       @property (nonatomic) NSString *sessionPreset; // 默认 AVCaptureSessionPresetMedium

       */
      WS_MediaCaptureManagerVideoProfile *profile = [[WS_MediaCaptureManagerVideoProfile alloc] init];
      profile.videoType = 0;
      profile.videoFrameDuration = CMTimeMake(3000, 100);
      profile.videoDevicePosition = AVCaptureDevicePositionBack;
      profile.videoSize = CGSizeMake(1280, 720);
      profile.sessionPreset = AVCaptureSessionPreset1280x720;
      [self.recorder startRecordVideo:nil];

      AVCaptureVideoPreviewLayer *previewLayer = self.recorder.previewLayer;
      if (previewLayer) {
        previewLayer.frame = self.viewPreview.layer.bounds;
        [self.viewPreview.layer addSublayer:previewLayer];
      }
      [self.videoPlayer setPause:NO];
      self.videoPlayer.frame = self.videoShow.bounds;
    } break;
    case 110: // stop video
    {
      [self.recorder stopRecordVideo];
        [self.viewPreview.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperlayer];
        }];
      [self.videoPlayer setPause:YES];
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
