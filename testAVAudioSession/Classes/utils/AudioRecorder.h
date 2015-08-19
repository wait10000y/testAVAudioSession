//
//  AudioRecorder.h
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioRecorderDelegate <NSObject>

-(void)audioRecorder:(id)recorder audioPart:(id)theData;


@end

@interface AudioRecorder : NSObject


-(BOOL)startAudioSessonWithPrifile:(NSDictionary*)theData;
-(BOOL)endAudioSession;

-(BOOL)startAudioRecorder:(id)theData;
-(BOOL)puseAudioRecorder;
-(BOOL)stopAudioRecorder;


@end
