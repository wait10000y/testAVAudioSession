//
//  ViewController.h
//  testAVAudioSession
//
//  Created by wsliang on 15/7/6.
//  Copyright (c) 2015年 wsliang. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WS_VideoPlayer.h"




@interface ViewController : UIViewController


- (IBAction)actionOperations:(UIButton *)sender;


@property (weak, nonatomic) IBOutlet UIView *viewPreview;

@property (weak, nonatomic) IBOutlet UIImageView *imgShow;

@property (weak, nonatomic) IBOutlet UIView *videoShow;

@end
