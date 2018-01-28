//
//  GACodec.h
//  FFMPEGdemo
//
//  Created by XDS on 2018/1/25.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface GACodec : NSObject

/* 输出图像大小。默认设置为源大小。 */
@property (nonatomic,assign) int outputWidth, outputHeight;

@property (nonatomic, strong) UIImage *currentImage;

- (id)initWithVideo:(NSString *)path;


- (BOOL)nextFrame;

- (UIImage *)getNextFrame;
- (UIImage *)imageFromAVPicture;
@end
