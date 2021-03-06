//
//  AudioManager.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "AudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define checkResult(result,operation) (_checkResult((result),(operation),strrchr(__FILE__, '/')+1,__LINE__))
static inline BOOL _checkResult(OSStatus result, const char *operation, const char* file, int line) {
  if ( result != noErr ) {
    NSLog(@"%s:%d: %s result %d %08X %4.4s\n", file, line, operation, (int)result, (int)result, (char*)&result);
    return NO;
  }
  return YES;
}


@interface AudioManager () {
  AudioUnit _audioUnit;
}
@property (nonatomic, strong) id observerToken;
@end

@implementation AudioManager

- (BOOL)begin
{
  if ( ![self startAudioSystem] ) {
    // Work around an iOS 7 audio interruption bug
    [self teardownAudioSystem];
    [self setupAudioSystem];
    [self startAudioSystem];
  }
  return YES;
}

-(BOOL)end
{
  return [self stopAudioSystem];
//  [self teardownAudioSystem];
}

-(void)dealloc {
  [self teardownAudioSystem];
}

- (void)setupAudioSystem {
  
  NSError *error = nil;
  if ( ![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error] ) {
    NSLog(@"Couldn't set audio session category: %@", error);
  }
  
  if ( ![[AVAudioSession sharedInstance] setPreferredIOBufferDuration:(128.0/44100.0) error:&error] ) {
    NSLog(@"Couldn't set preferred buffer duration: %@", error);
  }
  
  if ( ![[AVAudioSession sharedInstance] setActive:YES error:&error] ) {
    NSLog(@"Couldn't set audio session active: %@", error);
  }
  
  // Create the audio unit
  AudioComponentDescription desc = {
    .componentType = kAudioUnitType_Output,
    .componentSubType = kAudioUnitSubType_VoiceProcessingIO,
    .componentManufacturer = kAudioUnitManufacturer_Apple,
    .componentFlags = 0,
    .componentFlagsMask = 0
  };
  
  AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
  checkResult(AudioComponentInstanceNew(inputComponent, &_audioUnit), "AudioComponentInstanceNew");
  
  // Enable input
  UInt32 enableFlag = 1;
  checkResult(AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableFlag, sizeof(enableFlag)),
              "kAudioOutputUnitProperty_EnableIO");
  
  // open all
  const UInt32 kInputBus = 1;
  const UInt32 one = 1;
  const UInt32 zero = 0;
  AudioUnitSetProperty(_audioUnit, kAUVoiceIOProperty_BypassVoiceProcessing, kAudioUnitScope_Global, kInputBus, &zero, sizeof(zero));
  AudioUnitSetProperty(_audioUnit, kAUVoiceIOProperty_VoiceProcessingEnableAGC, kAudioUnitScope_Global, kInputBus, &one, sizeof(one));
  AudioUnitSetProperty(_audioUnit, kAUVoiceIOProperty_DuckNonVoiceAudio, kAudioUnitScope_Global, kInputBus, &one, sizeof(one));
  
  
  // Set the stream formats
  AudioStreamBasicDescription clientFormat = [AudioManager nonInterleavedFloatStereoAudioDescription];
  checkResult(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &clientFormat, sizeof(clientFormat)),
              "kAudioUnitProperty_StreamFormat");
  checkResult(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &clientFormat, sizeof(clientFormat)),
              "kAudioUnitProperty_StreamFormat");
  
  // Set the render callback
  AURenderCallbackStruct rcbs = { .inputProc = audioUnitRenderCallback, .inputProcRefCon = (__bridge void *)(self) };
  checkResult(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &rcbs, sizeof(rcbs)),
              "kAudioUnitProperty_SetRenderCallback");
  
  UInt32 framesPerSlice = 4096;
  checkResult(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framesPerSlice, sizeof(framesPerSlice)),
              "AudioUnitSetProperty(kAudioUnitProperty_MaximumFramesPerSlice");
  
  // Initialize the audio unit
  checkResult(AudioUnitInitialize(_audioUnit), "AudioUnitInitialize");
  
  // Watch for session interruptions
  self.observerToken =
  [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
    NSInteger type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
    if ( type == AVAudioSessionInterruptionTypeBegan ) {
      [self stopAudioSystem];
    } else {
      if ( ![self startAudioSystem] ) {
        // Work around an iOS 7 audio interruption bug
        [self teardownAudioSystem];
        [self setupAudioSystem];
        [self startAudioSystem];
      }
    }
  }];
}

- (void)teardownAudioSystem {
  if ( _audioUnit ) {
    checkResult(AudioComponentInstanceDispose(_audioUnit), "AudioComponentInstanceDispose");
    _audioUnit = NULL;
  }
  
  if ( _observerToken ) {
    [[NSNotificationCenter defaultCenter] removeObserver:_observerToken];
    self.observerToken = nil;
  }
}

- (BOOL)stopAudioSystem {
  checkResult(AudioOutputUnitStop(_audioUnit), "AudioOutputUnitStop");
  [[AVAudioSession sharedInstance] setActive:NO error:NULL];
  return YES;
}

- (BOOL)startAudioSystem {
  NSError *error = nil;
  if ( ![[AVAudioSession sharedInstance] setActive:YES error:&error] ) {
    NSLog(@"Couldn't activate audio session: %@", error);
    return NO;
  }
  
  if ( !checkResult(AudioOutputUnitStart(_audioUnit), "AudioOutputUnitStart") ) {
    return NO;
  }
  
  return YES;
}

+ (AudioStreamBasicDescription)nonInterleavedFloatStereoAudioDescription {
  AudioStreamBasicDescription audioDescription;
  memset(&audioDescription, 0, sizeof(audioDescription));
  audioDescription.mFormatID          = kAudioFormatLinearPCM;
  audioDescription.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
  audioDescription.mChannelsPerFrame  = 2;
  audioDescription.mBytesPerPacket    = sizeof(float);
  audioDescription.mFramesPerPacket   = 1;
  audioDescription.mBytesPerFrame     = sizeof(float);
  audioDescription.mBitsPerChannel    = 8 * sizeof(float);
  audioDescription.mSampleRate        = 44100.0;
  return audioDescription;
}

static OSStatus audioUnitRenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
  
  __unsafe_unretained AudioManager *THIS = (__bridge AudioManager*)inRefCon;
  
  // Draw from the system audio input
  OSStatus result = AudioUnitRender(THIS->_audioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
  checkResult(result, "AudioUnitRender");
  
  return result;
}



@end
