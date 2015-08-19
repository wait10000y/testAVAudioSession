//
//  AudioManager.h
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioManager : NSObject


-(BOOL)begin;
-(BOOL)end;


- (void)setupAudioSystem;
- (BOOL)startAudioSystem;

- (BOOL)stopAudioSystem;
- (void)teardownAudioSystem;

@end
