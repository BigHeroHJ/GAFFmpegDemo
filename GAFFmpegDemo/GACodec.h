//
//  GACodec.h
//  FFMPEGdemo
//
//  Created by XDS on 2018/1/25.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class CG_Frame_YUV;

@protocol GACodecDelegat<NSObject>
@optional
- (void)updateDisplayFrame:(CG_Frame_YUV *)yuvFrame;
@end

@interface GACodec : NSObject
@property (nonatomic, weak) id<GACodecDelegat>delegate;

/* 输出图像大小。默认设置为源大小。 */
@property (nonatomic,assign) int outputWidth, outputHeight;

@property (nonatomic, strong) UIImage *currentImage;

- (id)initWithVideo:(NSString *)path;

- (BOOL)nextFrame;

- (UIImage *)getNextFrame;
- (UIImage *)imageFromAVPicture;
- (void)nextDisplayFrame;
@end
