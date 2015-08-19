//
//  AVCaptureManager.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "AVCaptureManager.h"

#import "TPCircularBuffer.h"

#define kBufferLength 2048

typedef enum : NSInteger {
  SessionStatus_Default = 0,
  SessionStatus_Created = 1,
  SessionStatus_Started = 2,
  SessionStatus_Error = -1
} SessionStatusTag;

@interface AVCaptureManager()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic) AVCaptureDeviceInput *audioInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property SessionStatusTag sessionStatus; // 0:default,1:created,2:started,-1:error

//@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t audioQueue;
@property (nonatomic) dispatch_queue_t videoQueue;


@end

@implementation AVCaptureManager
{
  struct AVCaptureManagerRecordStatus mStatus;
  TPCircularBuffer buffer;
  AudioConverterRef m_converter;
}

@synthesize status = mStatus;

- (instancetype)init
{
  self = [super init];
  if (self) {
    NSLog(@"---- AVCaptureManager init ----");
    self.sessionStatus = SessionStatus_Default;
    self.videoOrientation = 1;
  }
  return self;
}

- (void)setup {
  // Initialise buffer
  TPCircularBufferInit(&buffer, kBufferLength);
  
  // Setup audio, etc
}

- (void)dealloc {
  // Release buffer resources
  TPCircularBufferCleanup(&buffer);
}

-(BOOL)createRecordSession
{
  NSLog(@"---- AVCaptureManager createRecordSession ----");
  if (self.sessionStatus == SessionStatus_Started || self.sessionStatus == SessionStatus_Created) {
    return YES;
  }
  
  if (_session) {[self endRecordSession];}
  
  if (_audioQueue == NULL) {
    _audioQueue = dispatch_queue_create("com.mypage.videolive_audioQueue", NULL);
  }
  if (_videoQueue == NULL) {
    _videoQueue = dispatch_queue_create("com.mypage.videolive_videoQueue", NULL);
  }
  
  _session =[[AVCaptureSession alloc] init ];
  if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
  }
  
  /*********开始配置***************************/
//  [_session beginConfiguration];
//  
//  [_session commitConfiguration];
  /*********结束配置***************************/
  self.sessionStatus = SessionStatus_Created;
  return YES;
}

- (void)setVideoFrameRateWithDuration:(CMTime)frameDuration OnCaptureDevice:(AVCaptureDevice *)device
{
  if ([UIDevice currentDevice].systemVersion.intValue >=7) {
    NSError *error;
    NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for(AVFrameRateRange *range in supportedFrameRateRanges){
      if(CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) && CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)){
        frameRateSupported = YES;
      }
    }
    if(frameRateSupported && [device lockForConfiguration:&error]){
      [device setActiveVideoMaxFrameDuration:frameDuration];
      [device setActiveVideoMinFrameDuration:frameDuration];
      [device unlockForConfiguration];
    }
  }else{
    AVCaptureConnection * connection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isVideoMaxFrameDurationSupported]) {
      connection.videoMaxFrameDuration = frameDuration;
    }
    if ([connection isVideoMinFrameDurationSupported]) {
      connection.videoMinFrameDuration = frameDuration;
    }
  }
}

-(AVCaptureVideoDataOutput*)createVideoOutput:(id)theData
{
  NSLog(@"---- AVCaptureManager createVideoOutput ----");
  /** 视频输出 **/
  AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  //iphone 4s 5.0.1 supported list:
  //kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
  //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
  //kCVPixelFormatType_32BGRA
  // Specify the pixel format
  //  NSDictionary* settings = [[NSDictionary alloc] initWithObjectsAndKeys:
  //                            [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],kCVPixelBufferPixelFormatTypeKey,
  //                            [NSNumber numberWithInt: videoSetings.distWidth], (id)kCVPixelBufferWidthKey,
  //                            [NSNumber numberWithInt: videoSetings.distHeight], (id)kCVPixelBufferHeightKey,nil];
  
  NSDictionary *videoOutputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
  [videoOutput setVideoSettings:videoOutputOptions];
  [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoOutput setSampleBufferDelegate:self queue:_videoQueue];
  return videoOutput;
}

-(AVCaptureDeviceInput*)createVideoInput:(id)theData
{
  //设置前置摄像头
  AVCaptureDevice *videoDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];
  if (!videoDevice) {
    videoDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionUnspecified];
  }
  if (!videoDevice) {
    NSLog(@"---- video device null ----");
    return nil;
  }
  
  //视频输入
  return [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
}

-(AVCaptureAudioDataOutput*)createAudioOutput:(id)theData
{
  NSLog(@"---- AVCaptureManager createAudioOutput ----");
  //音频输出
  AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
  [audioOutput setSampleBufferDelegate:self queue:_audioQueue];
  //  dispatch_release(audioQueue);
  return audioOutput;
}

-(AVCaptureDeviceInput*)createAudioInput:(id)theData
{
  //设置micphone
  AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  if (!audioDevice) {
    NSLog(@"---- audio device null ----");
    return nil;
  }
  //音频输入
  return [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
}

// 获取 指定 摄像设备
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position
{
  NSLog(@"---- AVCaptureManager getCameraDeviceWithPosition:%ld ----",position);
  NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *camera in cameras)
  {
    if ([camera position]==position)
    {
      return camera;
    }
  } return nil;
}

// ==================== api =====================

-(BOOL)startRecordSession
{
  NSLog(@"---- AVCaptureManager startRecordSession ----");
  if (self.sessionStatus == SessionStatus_Started) {
    return YES;
  }else if (self.sessionStatus == SessionStatus_Created){
    
  }else{
    [self createRecordSession];
  }
  //开始运行session
  if (_session) {
    @try {
      AVAudioSession *audioSession = [AVAudioSession sharedInstance];
      [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
      [audioSession setActive:YES error:nil];
      NSLog(@"--- AVAudioSession setCategory AVAudioSessionCategoryPlayAndRecord actived ---");
      [_session startRunning];
      self.sessionStatus = SessionStatus_Started;
    }
    @catch (NSException *exception) {
      NSLog(@"------ session startrun error:%@ ---------",exception);
      [self endRecordSession];
      self.sessionStatus = SessionStatus_Error;
      return NO;
    }
    return YES;
  }else{
    self.sessionStatus = SessionStatus_Default;
  }
  return NO;
}

-(BOOL)endRecordSession
{
  NSLog(@"---- AVCaptureManager endRecordSession ----");
  if (_previewLayer) {
    [_previewLayer removeFromSuperlayer];
  }
  _previewLayer = nil;
  [_session stopRunning];
  [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
  _session = nil;
  _audioInput = nil;
  _audioOutput = nil;
  _videoInput = nil;
  _videoOutput = nil;
  self.sessionStatus = SessionStatus_Default;
  return YES;
}

-(BOOL)startRecordAudio:(id)theData isNew:(BOOL)isNew
{
  NSLog(@"---- AVCaptureManager startRecordAudio,data:%@,isNew:%d ----",theData,isNew);
  if (self.sessionStatus != SessionStatus_Created || self.sessionStatus != SessionStatus_Started) {
    [self createRecordSession];
  }
  if (!_session) {
    NSLog(@"---- startRecordAudio error:session error ----");
    return NO;
  }
  if (isNew) {
    AVCaptureAudioDataOutput *oldOutPut;
    if (_audioOutput && [[_session outputs] containsObject:_audioOutput]) {
      oldOutPut = _audioOutput;
    }
    AVCaptureDeviceInput *oldInput;
    if (_audioInput && [[_session inputs] containsObject:_audioInput]) {
      oldInput = _audioInput;
    }
    
    BOOL isOK = YES;
    [self.session beginConfiguration];
    _audioOutput = [self createAudioOutput:theData];
    if (oldOutPut) {
      [_session removeOutput:oldOutPut];
    }
    if ([_session canAddOutput:_audioOutput])
    {
      [_session addOutput:_audioOutput];
    }else{
      NSLog(@"---- session addAudioOutput error ----");
      isOK = NO;
    }
    
    _audioInput = [self createAudioInput:theData];
    if (oldInput) {
      [_session removeInput:oldInput];
    }
    if ([_session canAddInput:_audioInput]) {
      [_session addInput:_audioInput];
    }else{
      NSLog(@"---- session addAudioInput error ----");
      isOK = NO;
    }
    [self.session commitConfiguration];
    if (!isOK) {
      return NO;
    }

  }else{
    if (!_audioOutput || !_audioInput) {
      return [self startRecordAudio:theData isNew:YES];
    }else{
      BOOL isOK = YES;
      [self.session beginConfiguration];
      if (![[_session outputs] containsObject:_audioOutput]) {
        if ([_session canAddOutput:_audioOutput])
        {
          [_session addOutput:_audioOutput];
        }else{
          NSLog(@"---- session addAudioOutput error ----");
          isOK = NO;
        }
      }
      
      if (![[_session inputs] containsObject:_audioInput]) {
        if ([_session canAddInput:_audioInput]) {
          [_session addInput:_audioInput];
        }else{
          NSLog(@"---- session addAudioInput error ----");
          isOK = NO;
        }
      }
      [self.session commitConfiguration];
      if (!isOK) {
        return NO;
      }
    }
    
  }
  return [self startRecordSession];
}

-(BOOL)stopRecordAudio
{
  NSLog(@"---- AVCaptureManager stopRecordAudio ----");
  //音频输出 去除
  [_session beginConfiguration];
  if (_audioInput && [[_session inputs] containsObject:_audioInput]) {
    [_session removeInput:_audioInput];
  }
  if (_audioOutput && [[_session outputs] containsObject:_audioOutput]) {
    [_session removeOutput:_audioOutput];
  }
  [self.session commitConfiguration];
  return YES;
}

-(BOOL)startRecordVideoWithPreview:(UIView*)theView withData:(id)theData isNew:(BOOL)isNew
{
  NSLog(@"---- AVCaptureManager startRecordVideoWithPreview,data:%@,isNew:%d ----",theData,isNew);
  if (self.sessionStatus != SessionStatus_Created || self.sessionStatus != SessionStatus_Started) {
    [self createRecordSession];
  }
  if (!_session) {
    NSLog(@"---- startRecordVideo error:session error ----");
    return NO;
  }
  
  if (isNew) {
    AVCaptureVideoDataOutput *oldOutPut;
    if (_videoOutput && [[_session outputs] containsObject:_videoOutput]) {
      oldOutPut = _videoOutput;
    }
    
    AVCaptureDeviceInput *oldInput;
    if (_videoInput && [[_session inputs] containsObject:_videoInput]) {
      oldInput = _videoInput;
    }
    
    BOOL isOK = YES;
    [self.session beginConfiguration];
    
    _videoOutput = [self createVideoOutput:theData];
    if ([_session canAddOutput:_videoOutput])
    {
      if (oldOutPut) {
        [_session removeOutput:oldOutPut];
      }
      [_session addOutput:_videoOutput];

    }else{
      NSLog(@"---- session addVideoOutput error ----");
      isOK = NO;
    }
    
    _videoInput = [self createVideoInput:theData];
    CMTime frameDuration = CMTimeMake(1, 20);
    [self setVideoFrameRateWithDuration:frameDuration OnCaptureDevice:_videoInput.device];
    if (oldInput) {
      [_session removeInput:oldInput];
    }
    if ([_session canAddInput:_videoInput])
    {
      [_session addInput:_videoInput];
    }else{
      NSLog(@"---- session addVideoInput error ----");
      isOK = NO;
    }
    [self.session commitConfiguration];
    if (!isOK) {
      return NO;
    }
  }else{
    if (!_videoOutput || !_videoInput) {
      return [self startRecordVideoWithPreview:theView withData:theData isNew:YES];
    }else{
      BOOL isOK = YES;
      [self.session beginConfiguration];
      if (![[_session outputs] containsObject:_videoOutput]) {
        if ([_session canAddOutput:_videoOutput])
        {
          [_session addOutput:_videoOutput];
        }else{
          NSLog(@"---- session addVideoOutput error ----");
          isOK = NO;
        }
      }
      
      if (![[_session inputs] containsObject:_videoInput]) {
        if ([_session canAddInput:_videoInput])
        {
          [_session addInput:_videoInput];
        }else{
          NSLog(@"---- session addVideoInput error ----");
          isOK = NO;
        }
      }
      [self.session commitConfiguration];
      if (!isOK) {
        return NO;
      }
    }
    
  }
  //绑定到一个layer,用于显示预览图像
  AVCaptureVideoPreviewLayer *preLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
//     preLayer = [videoConnection videoPreviewLayer];
  if (theView && preLayer) {
//    preLayer.videoGravity = AVLayerVideoGravityResizeAspect; // AVLayerVideoGravityResizeAspectFill
    [theView.layer addSublayer:preLayer];
    preLayer.frame = theView.layer.bounds;
  }
  _previewLayer = preLayer;
  NSLog(@"--- previewLayer :%@ ---",NSStringFromCGRect(_previewLayer.frame));
  NSLog(@"--- view Layer :%@ ,view:%@ ---",NSStringFromCGRect(theView.layer.frame),NSStringFromCGRect(theView.frame));
  return [self startRecordSession];
}

-(BOOL)stopRecordVideo
{
  NSLog(@"---- AVCaptureManager stopRecordVideo ----");
  if (_previewLayer) {
    [_previewLayer removeFromSuperlayer];
  }
  //视频输出 去除
  [_session beginConfiguration];
  if (_videoInput && [[_session inputs] containsObject:_videoInput]) {
    [_session removeInput:_videoInput];
  }
  
  if (_videoOutput && [[_session outputs] containsObject:_videoOutput]) {
    [_session removeOutput:_videoOutput];
  }
  [self.session commitConfiguration];
  return YES;
}


#pragma mark 切换前后摄像头 
/*
 AVCaptureDevicePositionUnspecified         = 0,
 AVCaptureDevicePositionBack                = 1,
 AVCaptureDevicePositionFront               = 2
 */
- (NSInteger)toggleCamaraInput
{
  AVCaptureDevice *currentDevice =[self.videoInput device];
  AVCaptureDevicePosition currentPosition=[currentDevice position];
//  [self removeNotificationFromCaptureDevice:currentDevice];
  AVCaptureDevice *toChangeDevice;
  AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
  if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront)
  {
    toChangePosition=AVCaptureDevicePositionBack;
  }
  toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
  NSLog(@"---- AVCaptureManager toggleCamaraInput,old:%ld,new:%ld ----",currentPosition,toChangePosition);
  
//  [self addNotificationToCaptureDevice:toChangeDevice];
  //获得要调整的设备输入对象
  AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
  //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
  [self.session beginConfiguration];
  //移除原有输入对象
  [self.session removeInput:self.videoInput];
  //添加新的输入对象
  if ([self.session canAddInput:toChangeDeviceInput])
  {
    [self.session addInput:toChangeDeviceInput];
    self.videoInput=toChangeDeviceInput;
  }
  //提交会话配置
  [self.session commitConfiguration];
  return toChangePosition;
}

/*
 2 倒立
 3 右旋90度
 4 左旋90
 1 正
 */
-(void)setVideoOrientation:(NSInteger)mVideoOrientation
{
  NSLog(@"---- AVCaptureManager setMVideoOrientation:%ld ----",(long)mVideoOrientation);
  if (_videoOrientation != mVideoOrientation && mVideoOrientation > 0 && mVideoOrientation < 5) {
    _videoOrientation = mVideoOrientation;
    if ([[_session outputs] containsObject:_videoOutput]) {
      [self.session beginConfiguration];
      AVCaptureConnection * videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
      if (videoConnection.supportsVideoOrientation) {
        [videoConnection setVideoOrientation:_videoOrientation];
      }
      [self.session commitConfiguration];
    }
  }
}

// ==================== api end =====================


#pragma mark --- capture delegate ---
// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    __weak typeof(self) weakSelf = self;
    if (captureOutput == self.videoOutput) {
      
//      NSLog(@"----- video buffer output ------");
      if ([self.delegateVideo respondsToSelector:@selector(videoRecordPartData:)]) {
        // Create a UIImage from the sample buffer data
        @autoreleasepool {
          UIImage *image = [self imageFromSampleBuffer:&sampleBuffer];
          [self.delegateVideo videoRecordPartData:image];
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        }];
        }
      }
      
      
    }else if (captureOutput == self.audioOutput){
      if ([self.delegateAudio respondsToSelector:@selector(audioRecordPartData:withDesc:)]) {
        
        // IPhone mic 的默认示例格式是线性 PCM，与 16 位样品。这可能是单声道还是立体声取决如果有外部麦克风或不。要计算 FFT 我们需要有一个浮法向量。幸运的是有一个加速函数，以做为我们的转换：
        // check what sample format we have
        // this should always be linear PCM
        // but may have 1 or 2 channels
//        CMAudioFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
//        const AudioStreamBasicDescription *desc = CFBridgingRelease(CMAudioFormatDescriptionGetStreamBasicDescription(format));
        
        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

//        const AudioStreamBasicDescription *desc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        
        AudioBufferList audioBufferList;
        CMBlockBufferRef blockBuffer;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
        
        NSMutableData *audioDatas = [[NSMutableData alloc] init];
        for (int y = 0; y < audioBufferList.mNumberBuffers; y++) {
          AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
          Float32 *frame = (Float32 *)audioBuffer.mData;
          [audioDatas appendBytes:frame length:audioBuffer.mDataByteSize];
          // Put audio into circular buffer
//          TPCircularBufferProduceBytes(&buffer, frame, audioBuffer.mDataByteSize);
          
//          NSLog(@"------- AudioBufferList:buffers:%u , frame size:%lu ---------",(unsigned int)audioBufferList.mNumberBuffers,audioBuffer.mDataByteSize);
        }
//        NSLog(@"----- audio buffer output bufflist data length:%lu ------",(unsigned long)audioDatas.length);
        CFRelease(blockBuffer);
        blockBuffer = NULL;
        [self.delegateAudio audioRecordPartData:audioDatas withDesc:formatDescription];
        
        
        // ------------ others begin --------------
        char szBuf[4096];
        int  nSize = sizeof(szBuf);
        
#if SUPPORT_AAC_ENCODER
        if ([self encoderAAC:sampleBuffer aacData:szBuf aacLen:&nSize] == YES)
        {
          [g_pViewController sendAudioData:szBuf len:nSize channel:0];
        }
#else //#if SUPPORT_AAC_ENCODER
        AudioStreamBasicDescription outputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)));
        nSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
        CMBlockBufferRef databuf = CMSampleBufferGetDataBuffer(sampleBuffer);
        if (CMBlockBufferCopyDataBytes(databuf, 0, nSize, szBuf) == kCMBlockBufferNoErr)
        {
//          [g_pViewController sendAudioData:szBuf len:nSize channel:outputFormat.mChannelsPerFrame];
        }
#endif
       // ------------ others end --------------
        
        
      }
    }else{
      NSLog(@"----- unknown buffer output ------");
    }
    
  
  
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//  NSLog(@"----- buffer did drop ------");
}

-(void)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
  const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
  
  size_t aclSize = 0;
  const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
  NSData *currentChannelLayoutData = nil;
  
  // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
  if ( currentChannelLayout && aclSize > 0 )
    currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
  else
    currentChannelLayoutData = [NSData data];
  
  NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                            [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
                                            [NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
                                            [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
                                            currentChannelLayoutData, AVChannelLayoutKey,
                                            nil];
  
//  if ([assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
//    
//    assetWriterAudioIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
//    assetWriterAudioIn.expectsMediaDataInRealTime = YES;
//    if ([assetWriter canAddInput:assetWriterAudioIn]) {
//      [assetWriter addInput:assetWriterAudioIn];
//      NSLog(@"add asset writer audio input.");
//    } else {
//      NSLog(@"Couldn't add asset writer audio input.");
//      return NO;
//    }
//  }
//  else {
//    NSLog(@"Couldn't apply audio output settings.");
//    return NO;
//  }
  
//  return YES;
}


// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef *) sampleBuffer
{
  UIImage *image;
  
  // Get a CMSampleBuffer's Core Video image buffer for the media data
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(*sampleBuffer);
  // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  
  // Get the number of bytes per row for the pixel buffer
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
  
  // Get the number of bytes per row for the pixel buffer
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  // Get the pixel buffer width and height
  size_t width = CVPixelBufferGetWidth(imageBuffer);
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  
  // Create a device-dependent RGB color space
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  // Create a bitmap graphics context with the sample buffer data
  CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                               bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
  // Create a Quartz image from the pixel data in the bitmap graphics context
  CGImageRef quartzImage = CGBitmapContextCreateImage(context);
  // Unlock the pixel buffer
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
  // Free up the context and color space
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  
  // Create an image object from the Quartz image
  image = [UIImage imageWithCGImage:quartzImage];
  //  UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
  
  // Release the Quartz image
  CGImageRelease(quartzImage);
  
  return (image);
}


#if SUPPORT_AAC_ENCODER

-(BOOL)createAudioConvert:(CMSampleBufferRef)sampleBuffer { //根据输入样本初始化一个编码转换器
  if (m_converter != NULL) { return TRUE; }
  
  AudioStreamBasicDescription inputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer))); // 输入音频格式
  AudioStreamBasicDescription outputFormat; // 这里开始是输出音频格式
  memset(&outputFormat, 0, sizeof(outputFormat));
  outputFormat.mSampleRate       = inputFormat.mSampleRate; // 采样率保持一致
  outputFormat.mFormatID         = kAudioFormatMPEG4AAC;    // AAC编码
  outputFormat.mChannelsPerFrame = 2;
  outputFormat.mFramesPerPacket  = 1024;                    // AAC一帧是1024个字节
  
  AudioClassDescription *desc = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
  if (AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, desc, &m_converter) != noErr)
  {
    CKPrint(@"AudioConverterNewSpecific failed");
    return NO;
  }
  return YES;
}

-(BOOL)encoderAAC:(CMSampleBufferRef)sampleBuffer aacData:(char*)aacData aacLen:(int*)aacLen { // 编码PCM成AAC
  if ([self createAudioConvert:sampleBuffer] != YES)
  {
    return NO;
  }
  
  CMBlockBufferRef blockBuffer = nil;
  AudioBufferList  inBufferList;
  if (CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inBufferList, sizeof(inBufferList), NULL, NULL, 0, &blockBuffer) != noErr)
  {
    CKPrint(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
    return NO;
  }
  // 初始化一个输出缓冲列表
  AudioBufferList outBufferList;
  outBufferList.mNumberBuffers              = 1;
  outBufferList.mBuffers[0].mNumberChannels = 2;
  outBufferList.mBuffers[0].mDataByteSize   = *aacLen; // 设置缓冲区大小
  outBufferList.mBuffers[0].mData           = aacData; // 设置AAC缓冲区
  UInt32 outputDataPacketSize               = 1;
  if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &inBufferList, &outputDataPacketSize, &outBufferList, NULL) != noErr)
  {
    CKPrint(@"AudioConverterFillComplexBuffer failed");
    return NO;
  }
  
  *aacLen = outBufferList.mBuffers[0].mDataByteSize; //设置编码后的AAC大小
  CFRelease(blockBuffer);
  return YES;
}

-(AudioClassDescription*)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer { // 获得相应的编码器
  static AudioClassDescription audioDesc;
  
  UInt32 encoderSpecifier = type, size = 0;
  OSStatus status;
  
  memset(&audioDesc, 0, sizeof(audioDesc));
  status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
  if (status)
  {
    return nil;
  }
  
  uint32_t count = size / sizeof(AudioClassDescription);
  AudioClassDescription descs[count];
  status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descs);
  for (uint32_t i = 0; i < count; i++)
  {
    if ((type == descs[i].mSubType) && (manufacturer == descs[i].mManufacturer))
    {
      memcpy(&audioDesc, &descs[i], sizeof(audioDesc));
      break;
    }
  }
  return &audioDesc;
}

OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData,AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) { //<span style="font-family: Arial, Helvetica, sans-serif;">AudioConverterFillComplexBuffer 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据</span>
  AudioBufferList bufferList = *(AudioBufferList*)inUserData;
  ioData->mBuffers[0].mNumberChannels = 1;
  ioData->mBuffers[0].mData           = bufferList.mBuffers[0].mData;
  ioData->mBuffers[0].mDataByteSize   = bufferList.mBuffers[0].mDataByteSize;
  return noErr;
}

#endif









@end
