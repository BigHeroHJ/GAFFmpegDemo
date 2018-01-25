//
//  GACodec.m
//  FFMPEGdemo
//
//  Created by XDS on 2018/1/25.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import "GACodec.h"

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale//swscale.h>
#include <libavutil/intreadwrite.h>

@interface GACodec()
{
    AVCodec          *codec;
    AVFormatContext  *_formateCtx;
    AVCodecContext   *_codecCtx;
}

@end

@implementation GACodec
- (id)initWithVideo:(NSString *)path
{
    self = [super init];
    if(self){
        [self initCodecWithPath:path];
    }
    return self;
}
- (void)initCodecWithPath:(NSString *)path
{
    avcodec_register_all();
    avformat_network_init();
    av_register_all();
    
    if(avformat_open_input(&_formateCtx, [path UTF8String], NULL, NULL) < 0 ){
        printf("open file failed");
        return;
    }
    
    if(avformat_find_stream_info(_formateCtx, NULL) < 0){
        printf("find stream failed");
        return;
    }
    
    
}
@end
