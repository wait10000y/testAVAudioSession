//
//  WS_VideoPlayer.h
//  testAVAudioSession
//
//  Created by 王士良 on 2016/10/26.
//  Copyright © 2016年 wsliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface WS_VideoPlayer : UIView

-(void)showVideoBuff:(CMSampleBufferRef*)bufferRef;

@end


@interface VideoBuffPlayer : WS_VideoPlayer

-(void)showVideoBuff:(CMSampleBufferRef*)bufferRef;

@end


@interface VideoImagePlayer : WS_VideoPlayer

-(void)showVideoBuff:(CMSampleBufferRef*)bufferRef;
-(void)showImage:(UIImage*)theImage;

@end
