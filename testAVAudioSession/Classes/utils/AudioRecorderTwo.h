//
//  AudioRecorderTwo.h
//  testAVAudioSession
//
//  Created by wsliang on 15/7/22.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AudioRecorderTwo : NSObject

//@property (nonatomic) AudioComponentInstance audioUnit;

-(BOOL)setupAudio;
-(void)start;
-(void)stop;
-(void)finished;

@end
