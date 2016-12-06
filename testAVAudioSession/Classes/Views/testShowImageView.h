//
//  testShowImageView.h
//  testAVAudioSession
//
//  Created by 王士良 on 2016/12/1.
//  Copyright © 2016年 wsliang. All rights reserved.
//

/**
 
-(void)testImageShow
{
    //  CALayer *newLayer = [[CALayer alloc] init];
    //  newLayer.frame = self.view.layer.frame;
    //  [self.view.layer addSublayer:newLayer];
  testShowImageView *tView = [[testShowImageView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:tView];
  [tView.layer setBackgroundColor:[UIColor cyanColor].CGColor];

  int fps = 40;
  uint32_t sleepTime = 1000000.0f/fps;
  NSLog(@"----- 设置 图片 刷新率:%d -----",fps);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    long index = 0;
    do {
      usleep(sleepTime);
      UIImage *testImage = [UIImage imageNamed:[NSString stringWithFormat:@"test%ld",(++index)%3]];
        //      [tView performSelectorOnMainThread:@selector(showImage:) withObject:testImage waitUntilDone:NO];
      [tView performSelectorOnMainThread:@selector(showImageInLayer:) withObject:testImage waitUntilDone:NO];

    } while (YES);
    
  });

  */


#import <UIKit/UIKit.h>

@interface testShowImageView : UIView


-(void)showImage:(UIImage*)theImage;
-(void)showImageInLayer:(UIImage*)theImage;


@end
