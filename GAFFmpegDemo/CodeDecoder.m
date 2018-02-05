//
//  CodeDecoder.m
//  FFMPEGdemo
//
//  Created by XDS on 2018/1/13.
//  Copyright © 2018年 MountainX. All rights reserved.
//http://blog.csdn.net/itpeng523/article/details/52242464
//http://blog.csdn.net/u013127850/article/details/52260667

#import "CodeDecoder.h"
#import <AVFoundation/AVFoundation.h>

#include <libavcodec/avcodec.h>

#include <libavutil/avutil.h>
#include <libswscale/swscale.h>
#import <libavformat/avio.h>
#import "CG_Frame_YUV.h"



@interface  CodeDecoder()
{
    AVFormatContext    *avFormatCtx;//文件信息
    AVCodecContext     *avCodecCtx;//文件编码
    
    AVCodec            *avCodec;//
    AVPacket           *avPacket;
    
    AVInputFormat      *inputFormat;
    AVStream           *avStream;
    NSInteger           videoStream;
    CGFloat             videoTimeBaes;
   
    CGFloat              fps;//每秒帧率
    CGFloat              timeBase;
    NSArray             *_videoStreams;//视频流集合
}

@end



@implementation CodeDecoder

- (id)init
{
    self = [super init];
    if(self)
    {
        avCodec = NULL;
        avPacket = NULL;
        avCodecCtx = NULL;
        
        av_register_all();//只要注册一次
        avcodec_register_all();
        avformat_network_init();
        
    }
    return self;
}

//中断函数 设置
static int interrupCallback(void *ctx)
{
    if(!ctx){
        return 0;
    }
    __unsafe_unretained CodeDecoder *coder = (__bridge CodeDecoder *)ctx;
    BOOL rueslt = [coder InterruptDecoder];
    return rueslt;
}

- (BOOL)InterruptDecoder
{
    if(_interruptBlock)
        return _interruptBlock();
    return NO;
}
- (void)openWithPath:(NSString *)path
{
    AVFormatContext *formatCtx = NULL;
    formatCtx = avformat_alloc_context();
    if(!formatCtx){
        NSLog(@"打开失败");
        return;
    }
    if(_interruptBlock){
        formatCtx = avformat_alloc_context();

        //中断函数 设置 参数1 是一个函数指针  第二个参数是 回调函数执行的参数
        AVIOInterruptCB cb = {interrupCallback,(__bridge void *)self};
        avFormatCtx->interrupt_callback = cb;//设置回调函数
    }
    
    int openResult = avformat_open_input(&formatCtx,  [path  cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL);
    avFormatCtx = formatCtx;
    if(openResult < 0 )
    {
        //        av_log(nil, AV_LOG_ERROR, "打开文件失败\n");
        avformat_free_context(formatCtx);
        char buf[] = "";
        av_strerror(openResult, buf, 1024);
        printf("打开视频失败：error-->:%d(%s)\n",openResult,buf);
        NSLog(@"打开视频失败\n");
        return;
    }
    
    if(avformat_find_stream_info(formatCtx, NULL) < 0){
        avformat_close_input(&formatCtx);
         NSLog(@"获取stream失败\n");
        return;
    }
    
    //这个就是调试函数 打印消息
    av_dump_format(avFormatCtx, 0, [path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], false);
    
    _videoStreams = [self openVideoStream];//获取video stream 中的 type 是video 类型的流
    
    for (NSNumber *NUMBER in _videoStreams) {
        NSInteger i_stream = [NUMBER integerValue];
        printf("-----:%d",formatCtx->streams[i_stream]->disposition);
        if(0 == (formatCtx->streams[i_stream]->disposition & AV_DISPOSITION_ATTACHED_PIC))
        {
            [self openVideoStream:i_stream];
        }
    }
    
}

- (void)openVideoStream:(NSInteger)stream_i
{
    AVCodecContext  *codecContext = avFormatCtx->streams[stream_i]->codec;
    
    //找到合适的解码器
    AVCodec  *codec = avcodec_find_decoder(codecContext->codec_id);
    if(codec == nil)
    {
        NSLog(@"解码器未找到");
        return;
    }
    int openResult = avcodec_open2(codecContext, codec, NULL);
    if(openResult < 0){
        NSLog(@"解码器打开失败0");
        return;
    }
    //找到打开解码器后 手动分配内存
    
    self.avFrame = av_frame_alloc();//
    if(!self.avFrame){
        avcodec_close(codecContext);
        NSLog(@"内存分配失败");
        return;
    }
    
    videoStream = stream_i;
    avCodecCtx = codecContext;
    
    AVStream * strea = avFormatCtx->streams[stream_i];
  
    avStreamFPSTimeBase(strea, 0.04, &fps, &timeBase);
}

- (void)play{
//    CGFloat  duration = 0.1f;
//
//    NSArray * resu = [self decodeFrames:duration];
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [self play];
//    });
}

- (BOOL)readFrame
{
     AVPacket  packet;

       int  getPic = 0;
      while (av_read_frame(avFormatCtx, &packet)>=0 && !getPic) {
         if(packet.stream_index == videoStream){
           
            getPic = avcodec_decode_video2(avCodecCtx, self.avFrame, &getPic, &packet);
            
             if(getPic < 0){
                 printf("codec error");
                 return nil;
             }
//             printf("getPic:%d\n",getPic);
//             printf("videoStream:%ld\n",videoStream);
//             printf("%s--size:%d \n","",avFrame->pkt_size);
//
             if(getPic != 0){
                 av_packet_unref(&packet);
                 // 释放YUV frame
//                 av_free(avFrame);
             }
//             if(getPic){//存在可解码数据
//                frameCount++;
//                UIImage *image = [self handleYUVToRGBWithSwsc:avFrame];
//                NSLog(@"image%@",image);
//                //printf("fram count:%d",frameCount);
//               // av_free(&packet);//用完及时 释放
//            }
        }
    }
    return getPic != 0;
}
- (void)releaseResources {
    // 释放frame
    av_packet_unref(&avPacket);
    // 释放YUV frame
    av_free(self.avFrame);
    // 关闭解码器
    if (avCodecCtx) avcodec_close(avCodecCtx);
    // 关闭文件
    if (avFormatCtx) avformat_close_input(&avFormatCtx);
    avformat_network_deinit();
}
- (UIImage *)handleYUVToRGBWithSwsc:(AVFrame *)frame
{
    float width = frame->width;
    float height = frame->height;
    AVPicture  avPicture ;
    avpicture_alloc(&avPicture, AV_PIX_FMT_RGB24, width, height);
    struct SwsContext * imageConvertCtx = sws_getContext(frame->width, frame->height, AV_PIX_FMT_YUV420P, frame->width, frame->height, AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    if(imageConvertCtx == NULL)
    {
        return nil;
    }
    sws_scale(imageConvertCtx, frame->data, frame->linesize, 0, frame->height, avPicture.data
              , avPicture.linesize);
    sws_freeVec(&imageConvertCtx);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef dataref = CFDataCreate(kCFAllocatorDefault, avPicture.data[0], avPicture.linesize[0] * height);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(dataref );
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();

    CGImageRef cgimageRef = CGImageCreate(frame->width, frame->height, 8, 24, avPicture.linesize[0], colorSpaceRef, bitmapInfo, provider, NULL, NO, NO);
    UIImage *image = [UIImage imageWithCGImage:cgimageRef];
    
    CGImageRelease(cgimageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CFRelease(dataref);
    
    return image;
}
-  (void)decodecFrame
{
    BOOL isfinished = NO;
    
    while (isfinished == NO) {
       
        if(avPacket->stream_index ==  videoStream){
            int packetSize = avPacket->size;
            while (packetSize > 0) {
                
                int getFrame = 0;
                int len = avcodec_decode_video2(avCodecCtx, self.avFrame, &getFrame, avPacket);
                if(len < 0){
                    NSLog(@"decode video error, skip packet");
                    break;
                }
                if(getFrame){
                    CG_Frame_YUV * yuvFrame = [self handleYUVFrame];
                  
                    isfinished = YES;
                    NSLog(@" decodec yuv frame:%@",yuvFrame.luma);
                    
                }
//                NSString * docuPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//                if([[NSFileManager defaultManager] fileExistsAtPath:[docuPath stringByAppendingPathComponent:@"yuv.data"]]){
//                    NSMutableArray *results = [NSMutableArray arrayWithContentsOfFile:[docuPath stringByAppendingPathComponent:@"yuv.data"]];
//                    [results addObjectsFromArray:result];
//
//                    [results writeToFile:[docuPath stringByAppendingPathComponent:@"yuv.data"] atomically:YES];
//                }else{
//                    [result writeToFile:[docuPath stringByAppendingPathComponent:@"yuv.data"] atomically:YES];
//                }
                av_free(avPacket);
            }
        }
        
    }
}
- (NSArray *)decodeFrames:(CGFloat)duration
{
    if(videoStream == -1){
        return nil;
    }
    NSMutableArray * result = [NSMutableArray array];
    AVPacket  packet;//包  存储 buffer data 包含size duration buf stream_index pos 等信息
    CGFloat decodedDuration = 0;
    BOOL isfinished = NO;
    
    while (isfinished == NO) {
        int readResult = av_read_frame(avFormatCtx, &packet);
        if (readResult < 0) {
             char buf[] = "";
            av_strerror(readResult, buf, 1024);
               printf("readFrames_error: %s\n",buf);
            break;
        }
        if(packet.stream_index ==  videoStream){
            int packetSize = packet.size;
            while (packetSize > 0) {
                int getFrame = 0;
                int len = avcodec_decode_video2(avCodecCtx, self.avFrame, &getFrame, &packet);
                if(len < 0){
                    NSLog(@"decode video error, skip packet");
                    break;
                }
                if(getFrame){
                    
                    CG_Frame_YUV * yuvFrame = [self handleYUVFrame];
                    [result addObject:yuvFrame];
                    
                    
                    NSLog(@"解码：%@",yuvFrame.luma);
                    decodedDuration += yuvFrame.duration;
                    if (decodedDuration > duration)
                        isfinished = YES;
                    
                }
               NSString * docuPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
                if([[NSFileManager defaultManager] fileExistsAtPath:[docuPath stringByAppendingPathComponent:@"yuv.data"]]){
                    NSMutableArray *results = [NSMutableArray arrayWithContentsOfFile:[docuPath stringByAppendingPathComponent:@"yuv.data"]];
                    [results addObjectsFromArray:result];
                    
                    [results writeToFile:[docuPath stringByAppendingPathComponent:@"yuv.data"] atomically:YES];
                }else{
                    [result writeToFile:[docuPath stringByAppendingPathComponent:@"yuv.data"] atomically:YES];
                }
                
            }
        }
        
    }
    return  result;
}

// avframe -> yuv 分量 需要研究y一下 : 这里是YUV420p 的格式 所以 传递的size width 和height U V 是一半
- (CG_Frame_YUV *)handleYUVFrame
{
    CG_Frame_YUV  * yuvFrame = [[CG_Frame_YUV alloc] init];
    yuvFrame.luma = copyFrameData(self.avFrame->data[0], self.avFrame->linesize[0], avCodecCtx->width, avCodecCtx->height);
    yuvFrame.chromaB = copyFrameData(self.avFrame->data[1], self.avFrame->linesize[1], avCodecCtx->width/2, avCodecCtx->height/2);
    yuvFrame.chromaR = copyFrameData(self.avFrame->data[2], self.avFrame->linesize[2], avCodecCtx->width/2, avCodecCtx->height/2);

    yuvFrame.width = avCodecCtx->width;
    yuvFrame.height = avCodecCtx->height;
    yuvFrame.position = av_frame_get_best_effort_timestamp(self.avFrame) * timeBase;
    
     const int64_t frameDuration = av_frame_get_pkt_duration(self.avFrame);
    
    if (frameDuration) {
        
        yuvFrame.duration = frameDuration * timeBase;
        yuvFrame.duration += self.avFrame->repeat_pict * timeBase * 0.5;
        
        //if (_videoFrame->repeat_pict > 0) {
        //    LoggerVideo(0, @"_videoFrame.repeat_pict %d", _videoFrame->repeat_pict);
        //}
        
    } else {
        
        // sometimes, ffmpeg unable to determine a frame duration
        // as example yuvj420p stream from web camera
        yuvFrame.duration = 1.0 / fps;
    }
    return  yuvFrame;
}

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}
static void avStreamFPSTimeBase(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
    {
        timebase = av_q2d(st->time_base);
        
    }else if(st->codec->time_base.den && st->codec->time_base.num)
    {
        timebase = av_q2d(st->codec->time_base);
    }else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1) {
        //timebase *= st->codec->ticks_per_frame;
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
    {
        fps = av_q2d(st->avg_frame_rate);
    }else if (st->r_frame_rate.den && st->r_frame_rate.num)
    {
        fps = av_q2d(st->r_frame_rate);
    }
    else{
         fps = 1.0 / timebase;
    }
    
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}

//从nb_streams 中获取类型是 video 的streams 是视频流
- (NSMutableArray *)openVideoStream
{
    NSMutableArray  *arrs = [NSMutableArray array];
    NSLog(@"streams count%u",avFormatCtx->nb_streams);
    for (int  i = 0; i < avFormatCtx->nb_streams; ++i) {
        if(avFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO){
         [arrs addObject:@(i)];
        }
    }
    return arrs;
}

//- (void)decoderWithLocalVideoPath:(NSString *)videoPath
//{
//   // av_open_input_file --- >avformat_open_input
//
//    avFormatCtx = avformat_alloc_context();
//    NSLog(@"char * --> videoPath %s",[videoPath UTF8String]);
//
//   const  char * filePath = [videoPath UTF8String];
//
//
//
//    int streamResult = avformat_find_stream_info(avFormatCtx, NULL);
//    if(streamResult < 0 ){
//        //失败检查stream 流失败 >= 0 为正常
//        NSLog(@"检查数据流失败\n");
//        return;
//    }
//
//    //获取 视频流
//    if(videoStream == av_find_best_stream(avFormatCtx,AVMEDIA_TYPE_VIDEO,-1,-1,&avCodec,0) < 0){
//        NSLog(@"no find first stream\n");
//        return;
//    }
//
//    avStream = avFormatCtx->streams[videoStream];
//    avCodecCtx = avStream->codec;
//
//#if DEBUG
//    av_dump_format(avFormatCtx, videoStream, [videoPath UTF8String], 0);
//#endif
//
//
//    avFrame = av_frame_alloc();
//
//    if(avStream->avg_frame_rate.den && avStream->avg_frame_rate.num)
//    {
//        fps = av_q2d(avStream->avg_frame_rate);
//    }else{
//        fps = 40;//获取不到就设置每秒切换40帧
//    }
//
//    //检查解码
//    avCodec = avcodec_find_decoder(avCodecCtx->codec_id);
//    if(avCodec == NULL){
//        NSLog(@"解码 no find\n");
//        return;
//    }
//
//    //打开解码器
//    if(avcodec_open2(avCodecCtx, avCodec, nil) < 0)
//    {
//        NSLog(@"解码器  open failed\n");
//        return;openResult    int    -1094995529
//    }
//
//    videoWidth = avCodecCtx->width;
//    videoHeight = avCodecCtx->height;
//
//}

@end
