//
//  testShowImageView.m
//  testAVAudioSession
//
//  Created by 王士良 on 2016/12/1.
//  Copyright © 2016年 wsliang. All rights reserved.
//

#import "testShowImageView.h"

@implementation testShowImageView
{
  UIImage *tempImage;
}

-(void)showImage:(UIImage*)theImage
{
  tempImage = theImage;
  [self setNeedsDisplay];
}

-(void)showImageInLayer:(UIImage*)theImage
{
  self.layer.contents = (__bridge id)(theImage.CGImage);
}


- (void)drawRect:(CGRect)rect {
  if (tempImage) {
    [tempImage drawInRect:rect];
  }

}


@end
