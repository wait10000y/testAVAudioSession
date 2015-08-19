//
//  AudioRecorderTwo.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/22.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "AudioRecorderTwo.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>


#define kOutputBus 0
#define kInputBus 1

//AudioComponentInstance audioUnit;

#define checkStatus(result) (_checkResult((result),strrchr(__FILE__, '/')+1,__LINE__))
static inline BOOL _checkResult(OSStatus result, const char* file, int line) {
  if ( result != noErr ) {
    NSLog(@"%s:%d: result %d %08X %4.4s\n", file, line, (int)result, (int)result, (char*)&result);
    return NO;
  }
  return YES;
}

@interface AudioRecorderTwo()
{
  AudioUnit audioUnit;
}
//@property (nonatomic) AudioComponentInstance audioUnit;

@end

@implementation AudioRecorderTwo
//{
//  AudioComponentInstance audioUnit;
//}


-(BOOL)setupAudio
{
  AVAudioSession* session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
  [session setActive:YES error:nil];
  [session setInputGain:0.5 error:nil];
  float aBufferLength = 0.05f; // In seconds
  [session setPreferredIOBufferDuration:aBufferLength error:nil];
  
  
  OSStatus status = noErr;
  
  // Describe audio component
  AudioComponentDescription desc;
  desc.componentType = kAudioUnitType_Output;
  desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
  desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  desc.componentFlags = 0;
  desc.componentFlagsMask = 0;
  
  // Get component
  AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
  
  // Get audio units
  status = AudioComponentInstanceNew(inputComponent, &audioUnit);
  checkStatus(status);
  
  // Enable IO for recording
  UInt32 flag = 1;
  status = AudioUnitSetProperty(audioUnit,
                                kAudioOutputUnitProperty_EnableIO,
                                kAudioUnitScope_Input,
                                kInputBus,
                                &flag,
                                sizeof(flag));
  checkStatus(status);
  
  // Enable IO for playback
  status = AudioUnitSetProperty(audioUnit,
                                kAudioOutputUnitProperty_EnableIO,
                                kAudioUnitScope_Output,
                                kOutputBus,
                                &flag,
                                sizeof(flag));
  checkStatus(status);
  
  // Describe format
  AudioStreamBasicDescription audioFormat;
  audioFormat.mSampleRate			= 44100.00;
  audioFormat.mFormatID			= kAudioFormatLinearPCM;
  audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  audioFormat.mFramesPerPacket	= 1;
  audioFormat.mChannelsPerFrame	= 1;
  audioFormat.mBitsPerChannel		= 16;
  audioFormat.mBytesPerPacket		= 2;
  audioFormat.mBytesPerFrame		= 2;
  
  // Apply format
  status = AudioUnitSetProperty(audioUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Output,
                                kInputBus,
                                &audioFormat,
                                sizeof(audioFormat));
  
  checkStatus(status);
  status = AudioUnitSetProperty(audioUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                kOutputBus,
                                &audioFormat,
                                sizeof(audioFormat));
  checkStatus(status);
  
  
  // Set input callback
  AURenderCallbackStruct callbackStruct;
  callbackStruct.inputProc = recordingCallback;
  callbackStruct.inputProcRefCon = (__bridge void *)(self);
  status = AudioUnitSetProperty(audioUnit,
                                kAudioOutputUnitProperty_SetInputCallback,
                                kAudioUnitScope_Global,
                                kInputBus,
                                &callbackStruct,
                                sizeof(callbackStruct));
  checkStatus(status);
  
  // Set output callback
  callbackStruct.inputProc = playbackCallback;
  callbackStruct.inputProcRefCon = (__bridge void *)(self);
  status = AudioUnitSetProperty(audioUnit,
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Global,
                                kOutputBus,
                                &callbackStruct,
                                sizeof(callbackStruct));
  checkStatus(status);
  
  // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
  flag = 0;
  status = AudioUnitSetProperty(audioUnit,
                                kAudioUnitProperty_ShouldAllocateBuffer,
                                kAudioUnitScope_Output,
                                kInputBus,
                                &flag,
                                sizeof(flag));
  
  // TODO: Allocate our own buffers if we want
  
  // Initialise
  status = AudioUnitInitialize(audioUnit);
  checkStatus(status);
  return status == noErr;
}

-(void)start
{
  OSStatus status = AudioOutputUnitStart(audioUnit);
  checkStatus(status);
}

-(void)stop
{
  OSStatus status = AudioOutputUnitStop(audioUnit);
  checkStatus(status);
}

-(void)finished
{
  AVAudioSession* session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayback error:nil];
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
  AudioComponentInstanceDispose(audioUnit);
}



static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
  
  // TODO: Use inRefCon to access our interface object to do stuff
  // Then, use inNumberFrames to figure out how much data is available, and make
  // that much space available in buffers in an AudioBufferList.
  
//  AudioBufferList *bufferList; // <- Fill this up with buffers (you will want to malloc it, as it's a dynamic-length list)
//  
//  bufferList = ioData;
  // Then:
  // Obtain recorded samples
  
  __unsafe_unretained AudioRecorderTwo *THIS = (__bridge AudioRecorderTwo*)inRefCon;
  
  OSStatus status;
  status = AudioUnitRender(THIS->audioUnit,
                           ioActionFlags,
                           inTimeStamp,
                           inBusNumber,
                           inNumberFrames,
                           ioData);
  checkStatus(status);
  
  // Now, we have the samples we just read sitting in buffers in bufferList
//  DoStuffWithTheRecordedAudio(bufferList);
  return noErr;
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
  // Notes: ioData contains buffers (may be more than one!)
  // Fill them up as much as you can. Remember to set the size value in each buffer to match how
  // much data is in the buffer.
  
  __unsafe_unretained AudioRecorderTwo *THIS = (__bridge AudioRecorderTwo*)inRefCon;
  
  OSStatus status;
  status = AudioUnitRender(THIS->audioUnit,
                           ioActionFlags,
                           inTimeStamp,
                           inBusNumber,
                           inNumberFrames,
                           ioData);
  checkStatus(status);
  
  return noErr;
}









@end
