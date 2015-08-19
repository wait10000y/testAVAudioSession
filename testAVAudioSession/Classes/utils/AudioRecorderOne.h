//
//  AudioPlayer.h
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioRecorderOne : NSObject

+(instancetype)defaultAudioRecord:(id)theProfile;

-(void)startAudioRecord;
-(void)stopAudioRecord;

-(void)openOrCloseEchoCancellation:(BOOL)theOpen;

-(void)inputAudioFrameList:(AudioBufferList *)thedata;

@end
