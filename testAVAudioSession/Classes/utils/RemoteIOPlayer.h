//
//  RemoteIOPlayer.h
//  RemoteIOTest
//
//  Created by Aran Mulholland on 3/03/09.
//  Copyright 2009 Aran Mulholland. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RemoteIOPlayerDelegate <NSObject>

-(UInt32)needNextPacket;

@end

@interface RemoteIOPlayer : NSObject

@property (weak, nonatomic) id<RemoteIOPlayerDelegate> sourceDelegate;

-(OSStatus)start;
-(OSStatus)stop;
-(void)cleanUp;
-(void)intialiseAudio;

@end
