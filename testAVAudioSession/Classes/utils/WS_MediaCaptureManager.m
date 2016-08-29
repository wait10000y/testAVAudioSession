//
//  WS_MediaCaptureManager.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "WS_MediaCaptureManager.h"

#define kBufferLength 2048

@implementation WS_MediaCaptureManagerVideoProfile
- (instancetype)init
{
  self = [super init];
  if (self) {
    _videoType          = 1;
    _videoFrameDuration = CMTimeMake(1, 20);
    _videoOrientation   = AVCaptureVideoOrientationPortrait;
    
    _videoDevicePosition = AVCaptureDevicePositionFront;
    _videoSize = CGSizeZero;
    _sessionPreset = AVCaptureSessionPresetMedium;
    
  }
  return self;
}
-(BOOL)isEqual:(WS_MediaCaptureManagerVideoProfile *)object
{
  if ([object isKindOfClass:[WS_MediaCaptureManagerVideoProfile class]]) {
    if (self == object) {
      return YES;
    }
    
    if((self.videoType == object.videoType) &&
       (CMTimeCompare(self.videoFrameDuration, object.videoFrameDuration)==0) &&
       (self.videoOrientation == object.videoOrientation) &&
       (self.videoDevicePosition == object.videoDevicePosition) &&
       (CGSizeEqualToSize(self.videoSize,object.videoSize)) &&
       (self.sessionPreset == object.sessionPreset)){
      return YES;
    }
    
  }
  return NO;
}
@end

@implementation WS_MediaCaptureManagerAudioProfile
- (instancetype)init
{
  self = [super init];
  if (self) {
    _audioChannels = 2;
    _audioSampleRate = 44100;
    _audioType = 1; // pcm
    _audioDura = 100;
  }
  return self;
}

-(BOOL)isEqual:(WS_MediaCaptureManagerAudioProfile *)object
{
  if ([object isKindOfClass:[WS_MediaCaptureManagerAudioProfile class]]) {
    if (self == object) {
      return YES;
    }
    
    if((self.audioChannels == object.audioChannels) &&
       (self.audioSampleRate == object.audioSampleRate) &&
       (self.audioType == object.audioType) &&
       (self.audioDura == object.audioDura)){
      return YES;
    }
    
  }
  return NO;
}
@end


@interface WS_MediaCaptureManager()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic) AVCaptureDeviceInput *audioInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic) AVCaptureAudioDataOutput *audioOutput;
//@property SessionStatusTag sessionStatus; // 0:default,1:created,2:started,-1:error

//@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t audioQueue;
@property (nonatomic) dispatch_queue_t videoQueue;

@end

@implementation WS_MediaCaptureManager
{
//  AudioConverterRef m_converter;
  AVCaptureVideoOrientation currentVideoOri;
}


- (instancetype)init
{
  self = [super init];
  if (self) {
    NSLog(@"---- WS_MediaCaptureManager init ----");
  }
  return self;
}

- (void)dealloc {

}

-(BOOL)createRecordSession
{
  
  if(_session){
    NSLog(@"---- WS_MediaCaptureManager createRecordSession: session already create----");
    return YES;
  }
  
  NSLog(@"---- WS_MediaCaptureManager createRecordSession ----");
  if (_audioQueue == NULL) {
    _audioQueue = dispatch_queue_create("WS_MediaCaptureManager_audioQueue", NULL);
  }
  if (_videoQueue == NULL) {
    _videoQueue = dispatch_queue_create("WS_MediaCaptureManager_videoQueue", NULL);
  }
  
  _session =[[AVCaptureSession alloc] init ];
  // AVCaptureSessionPresetHigh default
//  if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
//    [_session setSessionPreset:AVCaptureSessionPresetMedium];
//  }
  
  /*********开始配置***************************/
//  [_session beginConfiguration];
//  
//  [_session commitConfiguration];
  /*********结束配置***************************/
  return YES;
}

- (void)setVideoFrameRateWithDuration:(CMTime)frameDuration OnCaptureDevice:(AVCaptureDevice *)device
{
  // >=IOS7
  if ([UIDevice currentDevice].systemVersion.intValue >=7) {
    NSError *error;
    NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for(AVFrameRateRange *range in supportedFrameRateRanges){
      NSLog(@"--- FrameRate min%4.4f , max:%4.4f ---",range.minFrameRate,range.maxFrameRate);
      if(CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) && CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)){
        frameRateSupported = YES;
      }
    }
    if(frameRateSupported && [device lockForConfiguration:&error]){
      [device setActiveVideoMaxFrameDuration:frameDuration];
      [device setActiveVideoMinFrameDuration:frameDuration];
      [device unlockForConfiguration];
    }
  }else if([UIDevice currentDevice].systemVersion.intValue >=5){
    // <= IOS6
    AVCaptureConnection * connection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isVideoMaxFrameDurationSupported]) {
      connection.videoMaxFrameDuration = frameDuration;
    }
    if ([connection isVideoMinFrameDurationSupported]) {
      connection.videoMinFrameDuration = frameDuration;
    }
  }
}

-(AVCaptureVideoDataOutput*)createVideoOutput
{
  NSLog(@"---- WS_MediaCaptureManager createVideoOutput ----");
  if (!_videoProfile) {
    _videoProfile = [WS_MediaCaptureManagerVideoProfile new];
  }
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

  NSMutableDictionary *settings = [[NSMutableDictionary alloc]initWithCapacity:4];
  [settings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
  
  if (CGSizeEqualToSize(_videoProfile.videoSize, CGSizeZero)) {
    NSString *sPreset = _videoProfile.sessionPreset?:AVCaptureSessionPresetLow;
    [_session setSessionPreset:sPreset];
  }else{
    [settings setObject:@(_videoProfile.videoSize.width) forKey:(id)kCVPixelBufferWidthKey];
    [settings setObject:@(_videoProfile.videoSize.height) forKey:(id)kCVPixelBufferHeightKey];
  }
  
  [videoOutput setVideoSettings:settings];
  [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [videoOutput setSampleBufferDelegate:self queue:_videoQueue];
  
  return videoOutput;
}

-(AVCaptureDeviceInput*)createVideoInput
{
  if (!_videoProfile) {
    _videoProfile = [WS_MediaCaptureManagerVideoProfile new];
  }
  //设置前置摄像头
  AVCaptureDevice *videoDevice = [self getCameraDeviceWithPosition:_videoProfile.videoDevicePosition];
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

-(AVCaptureAudioDataOutput*)createAudioOutput
{
  NSLog(@"---- WS_MediaCaptureManager createAudioOutput ----");

  // TODO: 设置
//  AVAudioSession *aSession = [AVAudioSession sharedInstance];
//  aSession.sampleRate;
  
  //音频输出
  AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
  [audioOutput setSampleBufferDelegate:self queue:_audioQueue];
//  [audioOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:nil];

  //  dispatch_release(audioQueue);
  return audioOutput;
}

-(AVCaptureDeviceInput*)createAudioInput
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
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
  NSLog(@"---- WS_MediaCaptureManager getCameraDeviceWithPosition:%ld ----",(long)position);
  NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *camera in cameras)
  {
    if ([camera position]==position)
    {
      return camera;
    }
  }
  return nil;
}

// ==================== api =====================
// noErr,1:error;-1:session error
-(int)startRecordSession
{
  NSLog(@"---- WS_MediaCaptureManager startRecordSession ----");
  if(_session.isRunning || _session.interrupted){
    return noErr;
  }else if (!_session){
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
      return noErr;
    }
    @catch (NSException *exception) {
      NSLog(@"------ session startrun error:%@ ---------",exception);
      [self endRecordSession];
      return -1;
    }
    return noErr;
  }
  NSLog(@"------ session startrun error:session nil ---------");
  return 1;
}

-(int)endRecordSession
{
  NSLog(@"---- WS_MediaCaptureManager endRecordSession ----");

  [_session stopRunning];
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  [audioSession setActive:NO error:nil];

  _session = nil;
  _audioInput = nil;
  _audioOutput = nil;
  _videoInput = nil;
  _videoOutput = nil;
  _videoProfile = nil;
  _audioProfile = nil;
  _audioQueue = nil;
  _videoQueue = nil;
  return noErr;
}

// noErr:正常启动,-1:无法启动session;1:无法启动音频采集;
-(int)startRecordAudio:(WS_MediaCaptureManagerAudioProfile*)theProfile
{
  NSLog(@"---- WS_MediaCaptureManager startRecordAudio,data:%@ ----",theProfile);
  [self createRecordSession];
  
  if (!_session) {
    NSLog(@"---- startRecordAudio error:session error ----");
    return -1;
  }
// 判断 profile 是否相同
  if(theProfile==nil){
    if (!_audioProfile) {
      _audioProfile = [WS_MediaCaptureManagerAudioProfile new];
    }
    theProfile = _audioProfile;
  }else if(![theProfile isEqual:_audioProfile]){
    _audioProfile = theProfile;
  }
  
  // 创建或修改 input,output
  AVCaptureAudioDataOutput *oldOutPut;
  if (_audioOutput && [[_session outputs] containsObject:_audioOutput]) {
    oldOutPut = _audioOutput;
  }
  AVCaptureDeviceInput *oldInput;
  if (_audioInput && [[_session inputs] containsObject:_audioInput]) {
    oldInput = _audioInput;
  }
  
  int result = noErr;
  [self.session beginConfiguration];
  if (oldInput) {
    [_session removeInput:oldInput];
    oldInput = nil;
  }
  _audioInput = [self createAudioInput];
  if (_audioInput && [_session canAddInput:_audioInput]) {
    [_session addInput:_audioInput];
  }else{
    NSLog(@"---- session new addAudioInput error ----");
    result = 1;
  }
  
  if (oldOutPut) {
    [_session removeOutput:oldOutPut];
    oldOutPut = nil;
  }
  _audioOutput = [self createAudioOutput];
  if (_audioOutput && [_session canAddOutput:_audioOutput])
  {
    [_session addOutput:_audioOutput];
  }else{
    NSLog(@"---- session new addAudioOutput error ----");
    result = 1;
  }
  [self.session commitConfiguration];
  
  if (result == noErr) {
    return [self startRecordSession];
  }
  return result;
}

-(int)stopRecordAudio
{
  NSLog(@"---- WS_MediaCaptureManager stopRecordAudio ----");
  //音频输出 去除
  if (_session &&(_audioInput || _audioOutput)) {
    [_session beginConfiguration];
    if (_audioInput && [[_session inputs] containsObject:_audioInput]) {
      [_session removeInput:_audioInput];
    }
    if (_audioOutput && [[_session outputs] containsObject:_audioOutput]) {
      [_session removeOutput:_audioOutput];
    }
    [self.session commitConfiguration];
  }
  return noErr;
}

-(int)startRecordVideo:(WS_MediaCaptureManagerVideoProfile *)theProfile
{
  NSLog(@"---- WS_MediaCaptureManager startRecordVideoWithPreview,data:%@ ----",theProfile);
  [self createRecordSession];
  if (!_session) {
    NSLog(@"---- startRecordVideo error:session error ----");
    return -1;
  }
  
  // 判断 profile 是否相同
  if(theProfile==nil){
    if (!_videoProfile) {
      _videoProfile = [WS_MediaCaptureManagerVideoProfile new];
    }
    theProfile = _videoProfile;
  }else if(![theProfile isEqual:_videoProfile]){
    _videoProfile = theProfile;
  }
  
  // 创建和设置video input,output
  AVCaptureVideoDataOutput *oldOutPut;
  if (_videoOutput && [[_session outputs] containsObject:_videoOutput]) {
    oldOutPut = _videoOutput;
  }
  AVCaptureDeviceInput *oldInput;
  if (_videoInput && [[_session inputs] containsObject:_videoInput]) {
    oldInput = _videoInput;
  }
  
  int result = noErr;
  [self.session beginConfiguration];
  if (oldInput) {
    [_session removeInput:oldInput];
    oldInput = nil;
  }
  _videoInput = [self createVideoInput];
  if (_videoInput && [_session canAddInput:_videoInput])
  {
    [_session addInput:_videoInput];
  }else{
    NSLog(@"---- session addVideoInput error ----");
    result = 1;
  }
  
  if (oldOutPut) {
    [_session removeOutput:oldOutPut];
    oldOutPut = nil;
  }
  _videoOutput = [self createVideoOutput];
  if (_videoOutput && [_session canAddOutput:_videoOutput])
  {
    [_session addOutput:_videoOutput];
  }else{
    NSLog(@"---- session addVideoOutput error ----");
    result = 1;
  }
  
  CMTime frameDuration = _videoProfile.videoFrameDuration; // CMTimeMake(1, 20)
  [self setVideoFrameRateWithDuration:frameDuration OnCaptureDevice:_videoInput.device];
  
  AVCaptureConnection * videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
  if (videoConnection.supportsVideoOrientation) {
    [videoConnection setVideoOrientation:_videoProfile.videoOrientation];
    currentVideoOri = _videoProfile.videoOrientation;
  }
  
  [self.session commitConfiguration];
  if (result == noErr) {
    return [self startRecordSession];
  }
  return result;
}

-(int)stopRecordVideo
{
  NSLog(@"---- WS_MediaCaptureManager stopRecordVideo ----");
  if (_session && (_videoInput || _videoOutput)) {
    //视频输出 去除
    [_session beginConfiguration];
    if (_videoInput && [[_session inputs] containsObject:_videoInput]) {
      [_session removeInput:_videoInput];
    }
    
    if (_videoOutput && [[_session outputs] containsObject:_videoOutput]) {
      [_session removeOutput:_videoOutput];
    }
    [self.session commitConfiguration];
  }
  
  return noErr;
}

-(AVCaptureVideoPreviewLayer *)previewLayer
{
  if ([[_session outputs] containsObject:_videoOutput]) {
    AVCaptureConnection * videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoPreviewLayer *preLayer = [videoConnection videoPreviewLayer];
    if (!preLayer) {
      preLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    }
    NSLog(@"--- previewLayer :%@ ---",NSStringFromCGRect(preLayer.frame));
    return preLayer;
  }
  return nil;
}

-(AVCaptureDevicePosition)videoDevicePosition
{
  AVCaptureDevice *currentDevice =[self.videoInput device];
  return currentDevice.position;
}

-(AVCaptureVideoOrientation)videoOrientation
{
  AVCaptureConnection * videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
  return videoConnection.videoOrientation;
}

#pragma mark 切换前后摄像头 
/*
 AVCaptureDevicePositionUnspecified         = 0,
 AVCaptureDevicePositionBack                = 1,
 AVCaptureDevicePositionFront               = 2
 */
- (int)changeCamaraInput:(AVCaptureDevicePosition)toChangePosition
{
  AVCaptureDevice *currentDevice =[self.videoInput device];
  if (!currentDevice || toChangePosition == currentDevice.position) {
    return -1;
  }
  
//  [self removeNotificationFromCaptureDevice:currentDevice];
  AVCaptureDevice *toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];

  //获得要调整的设备输入对象
  AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
  if (toChangeDeviceInput) {
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
    
    AVCaptureConnection * videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if (videoConnection.supportsVideoOrientation) {
      [videoConnection setVideoOrientation:currentVideoOri];
    }
    //提交会话配置
    [self.session commitConfiguration];
//  [self addNotificationToCaptureDevice:toChangeDevice];
    return noErr;
  }

  return 1;
}

/*
 2 倒立
 3 右旋90度
 4 左旋90
 1 正
 */
-(int)changeVideoOrientation:(AVCaptureVideoOrientation)mVideoOrientation
{
  NSLog(@"---- WS_MediaCaptureManager setMVideoOrientation:%ld ----",(long)mVideoOrientation);
  if (self.videoOrientation != mVideoOrientation && mVideoOrientation > 0 && mVideoOrientation < 5) {
    if ([[_session outputs] containsObject:_videoOutput]) {
      [self.session beginConfiguration];
      AVCaptureConnection * videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
      if (videoConnection.supportsVideoOrientation) {
        [videoConnection setVideoOrientation:mVideoOrientation];
        currentVideoOri = mVideoOrientation;
      }
      [self.session commitConfiguration];
      return noErr;
    }
  }
  return 1;
}

// ==================== api end =====================


/*
 CMSampleBuffers are Core Foundation objects containing zero or more compressed (or uncompressed) samples of a particular media type (audio, video, muxed, etc), 
 that are used to move media sample data through the media system. A CMSampleBuffer can contain:
 
 A CMBlockBuffer of one or more media samples, or
 
 A CVImageBuffer, a reference to the format description for the stream of CMSampleBuffers, 
 size and timing information for each of the contained media samples, and both buffer-level and sample-level attachments.
 */
#pragma mark --- capture delegate ---
// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
  NSLog(@"----- captureOutput[%@] buffer[%@] ------",NSStringFromClass([captureOutput class]),[captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]?@"video":@"audio");
//    __weak typeof(self) weakSelf = self;
//  NSLog(@"---- isMainThread:%d ----",[NSThread isMainThread]); // no
    if (captureOutput == self.videoOutput) { // video

      if ([self.delegateVideo respondsToSelector:@selector(videoRecordPartData:)]) {
        // Create a UIImage from the sample buffer data
        @autoreleasepool {
          UIImage *image = [self imageFromSampleBuffer:&sampleBuffer];
          [self.delegateVideo videoRecordPartData:image];
        }
      }
      
    }else if (captureOutput == self.audioOutput){ // audio [captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]]

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




//-(void)dealloc
//{
//  [self endRecordSession];
//}






@end
