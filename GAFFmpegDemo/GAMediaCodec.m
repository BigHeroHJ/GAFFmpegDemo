//
//  GAMediaCodec.m
//  GAFFmpegDemo
//
//  Created by XDS on 2018/2/5.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import "GAMediaCodec.h"
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/frame.h>
#include <libavutil/avutil.h>


typedef enum : NSUInteger {
    VIDEOSTREAM = 1,
    AUDIOSTREAM,
} StreamType;

@interface GAMediaCodec()
{
    AVFormatContext  *_formatCtx;
    AVInputFormat    *_inputFormat;
    AVCodec          *_codec;
    AVCodecContext   *_codecCtx;
//
    AVFrame          *_avFrame;
    AVPacket         *_avPackt;
    
    //包含所有视频流index 的array
    NSMutableArray   *_videoStreamIndexs;
    NSString         *_sourcePath;
}

@end

@implementation GAMediaCodec

- (id)initWithSourcePath:(NSString *)sourcePath
{
    self = [super init];
    if(self){
        [self registerCodec];
        _sourcePath = sourcePath;
        
        [self openSource];
    }
    return self;
}

- (void)registerCodec
{
    //只需要注册一次
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
}
//打开 资源
- (BOOL)openSource
{
    
    if(avformat_open_input(&_formatCtx, [_sourcePath UTF8String], _inputFormat, NULL) < 0){
        printf("open file failed");
        return NO;
    }
    
    if(avformat_find_stream_info(_formatCtx, NULL) < 0)
    {
        printf("no find streams");
        return NO;
    }
    
    //找到这个formateCtx 中所有videostream
    _videoStreamIndexs = [self findVideoStream];
    
    //接下来去找 对应的streams 的codec
    for (NSNumber *num in _videoStreamIndexs) {
        int index = [num intValue];
        if ((_formatCtx->streams[index]->disposition & AV_DISPOSITION_DEFAULT) == 0) {
            [self openStream:index];
        }
    }
    
    return  YES;
}

/**
 find video streams
 */
- (NSMutableArray *)findVideoStream
{
    NSMutableArray * arr = [NSMutableArray array];
    for ( unsigned int i =0 ; i < _formatCtx->nb_streams; i++) {
        //找到 这个formateCtx 中 每个streams 中的解码器 对应的meido type 对应的index
        if(_formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            [arr addObject:@(i)];
        }
    }
    return arr;
}

/**
 find stream -> codec
 */
- (void)openStream:(int)streamIndex
{
    //从formateCtx 中找到 codecContext
   AVCodecContext * codecCtx = _formatCtx->streams[streamIndex]->codec;
    
    //找到对应 codec
    AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
    if(codec == NULL){
        printf("not find codec");
        return ;
    }
    //打开codec
    if(avcodec_open2(codecCtx, codec, NULL) < 0){
        printf("open codec failed");
        return;
    }
    
    //分配 帧内存
    _avFrame = av_frame_alloc();
    
    if(_avFrame == NULL){
        printf("frame malloc falied");
        return;
    }
    
    //赋给全局变量 成功找到codec后
    _codec = codec;
    _codecCtx = codecCtx;
    
    AVStream * stream = _formatCtx->streams[streamIndex];
    findTimeBaseFps(&_fps, &_timeBase, stream);
}

//计算 fps
void findTimeBaseFps(float *fps ,float * timeBase,AVStream * stream)
{
    float timeB,FPS;
    //timebase 分子分母都存在
    if(stream->time_base.den && stream->time_base.num){
        timeB = av_q2d(stream->time_base);//分子除以分母的结果
    }else if(stream->codec->time_base.den && stream->codec->time_base.num){//stream 中不存在den 或者num  则询问codec 中的timebase
        timeB = av_q2d(stream->codec->time_base);
    }else{
        timeB = 1 / 25;
    }
    
    //计算fps
    if(stream->avg_frame_rate.den && stream->avg_frame_rate.num){
        FPS = av_q2d(stream->avg_frame_rate);//计算
    }else if(stream->r_frame_rate.den && stream->r_frame_rate.num){
        FPS = av_q2d(stream->r_frame_rate);
    }else{
        FPS = 1.0f / timeB;
    }
    
    *timeBase = timeB;
    *fps = FPS;
}

@end
