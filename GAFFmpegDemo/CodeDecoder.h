//
//  CodeDecoder.h
//  FFMPEGdemo
//
//  Created by XDS on 2018/1/13.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <libavformat/avformat.h>

typedef int(^interruptBlock)(void);

@interface CodeDecoder : NSObject
{
    float   videoWidth;
    float   videoHeight;
}
@property (nonatomic, assign) AVFrame *avFrame;//每一帧的数据信息保存 colorrange opaue buf quality pict_type linesize data..
@property (nonatomic, copy) interruptBlock  interruptBlock;

- (void)openWithPath:(NSString *)path;
- (void)play;
- (BOOL)readFrame;
- (void)decodecFrame;
- (UIImage *)handleYUVToRGBWithSwsc:(AVFrame *)frame;
//- (void)decoderWithLocalVideoPath:(NSString *)videoPath;
@end
