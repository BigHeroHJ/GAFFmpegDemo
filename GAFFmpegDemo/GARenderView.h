//
//  GARenderView.h
//  GAFFmpegDemo
//
//  Created by XDS on 2018/1/30.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CG_Frame_YUV;

@interface GARenderView : UIView
- (void)renderFrame:(CG_Frame_YUV *) frame;
@end
