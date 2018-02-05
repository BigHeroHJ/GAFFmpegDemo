//
//  GAMediaCodec.h
//  GAFFmpegDemo
//
//  Created by XDS on 2018/2/5.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GAMediaCodec : NSObject

/**
 输入输出的 宽度 高度
 */
@property (nonatomic, assign) int  _outputWidth;
@property (nonatomic, assign) int  _outputHeight;

@property (nonatomic, assign) float fps;//视频帧率
@property (nonatomic, assign) float timeBase;//时间刻度

- (id)initWithSourcePath:(NSString *)sourcePath;

@end
