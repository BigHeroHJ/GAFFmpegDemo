//
//  CodeDecoder.h
//  FFMPEGdemo
//
//  Created by XDS on 2018/1/13.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef int(^interruptBlock)(void);

@interface CodeDecoder : NSObject
{
    float   videoWidth;
    float   videoHeight;
}

@property (nonatomic, copy) interruptBlock  interruptBlock;

- (void)openWithPath:(NSString *)path;
- (void)play;
- (UIImage *)readFrame;
- (void)decodecFrame;
//- (void)decoderWithLocalVideoPath:(NSString *)videoPath;
@end
