//
//  AudioRecorder.m
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import "AudioRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioRecorder()



@end
@implementation AudioRecorder



-(BOOL)startAudioSessonWithPrifile:(NSDictionary*)theData
{
  
  NSError *error;
  AVAudioSession *avSession = [AVAudioSession sharedInstance];
  
  [avSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
  // 0.93 - 0.005
  [avSession setPreferredIOBufferDuration:0.1f error:nil];
  [avSession setPreferredOutputNumberOfChannels:1 error:nil];
  // 8000 - 48000
  [avSession setPreferredSampleRate:44100.0 error:nil];
  
  // 增益 0 - 1.0;
  if (avSession.inputGainSettable) {
    [avSession setInputGain:0.5f error:nil];
  }
  
  BOOL result = [avSession setActive:YES error:&error];
  if (!result) {
    NSLog(@"---- avsession active error:%@ ----",error);
  }
  
  
  return result;
}

-(BOOL)endAudioSession
{
  AVAudioSession *avSession = [AVAudioSession sharedInstance];
  [avSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  [avSession setActive:NO error:nil];
  return YES;
}


-(BOOL)startAudioRecorder:(id)theData
{
  NSDictionary *setting = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithFloat: 44100.0],AVSampleRateKey,
                           [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                           [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                           nil];
  
  //然后直接把文件保存成.wav就好了
  NSURL *tmpFile = [NSURL fileURLWithPath:
             [NSTemporaryDirectory() stringByAppendingPathComponent:
              [NSString stringWithFormat: @"%@.%@",
               @"wangshuo",
               @"caf"]]];
  
  AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:tmpFile settings:setting error:nil];
  [recorder setDelegate:self];
  [recorder prepareToRecord];
  return [recorder record];
}

-(BOOL)puseAudioRecorder
{
  return NO;
}

-(BOOL)stopAudioRecorder
{
  return NO;
}




@end
