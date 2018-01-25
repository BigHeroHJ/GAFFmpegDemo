//
//  CG_Frame_YUV.h
//  FFMPEGdemo
//
//  Created by XDS on 2018/1/21.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface CG_Frame_YUV : NSObject

//YUV 分量的三个
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;

@property (nonatomic, assign) unsigned int width;
@property (nonatomic, assign) unsigned int height;
@property (readwrite, nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;

@end
