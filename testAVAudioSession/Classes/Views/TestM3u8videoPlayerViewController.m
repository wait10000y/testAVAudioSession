//
//  TestM3u8videoPlayerViewController.m
//  testAVAudioSession
//
//  Created by 王士良 on 2016/12/19.
//  Copyright © 2016年 wsliang. All rights reserved.
//

#import "TestM3u8videoPlayerViewController.h"
#import <MediaPlayer/MPMoviePlayerViewController.h>

@interface TestM3u8videoPlayerViewController ()

@end

@implementation TestM3u8videoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:nil];
  [self presentMoviePlayerViewControllerAnimated:player];

}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
