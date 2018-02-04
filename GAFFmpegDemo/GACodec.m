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
#import "CG_Frame_YUV.h"

@interface GACodec()
{
    AVCodec          *codec;
    AVFormatContext  *_formateCtx;
    AVCodecContext   *_codecCtx;
    
    
    NSInteger   videoStream_index;
    
    AVStream     *stream;
    
     double              fps;
    
    AVFrame      * avFrame;
    //AVPicture   _picture;
}

@end

@implementation GACodec

- (id)initWithVideo:(NSString *)path
{
    
    self = [super init];
    if(self){
        if( [self initCodecWithPath:path])
        {
            return self;
        }else{
            return nil;
        }
       
    }
    return self;
}
- (BOOL)initCodecWithPath:(NSString *)path
{
    avcodec_register_all();
    avformat_network_init();
    av_register_all();
    
    if(avformat_open_input(&_formateCtx, [path UTF8String], NULL, NULL) < 0 ){
        printf("open file failed");
        return NO;
    }
    
    if(avformat_find_stream_info(_formateCtx, NULL) < 0){
        printf("find stream failed");
        return NO;
    }
    
    if((videoStream_index = av_find_best_stream(_formateCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &codec, 0)) < 0)
    {
        printf("not find first stream");
        return NO;
    }
    
    stream = _formateCtx->streams[videoStream_index];
    _codecCtx = stream->codec;
    if(stream->avg_frame_rate.den && stream->avg_frame_rate.num)
    {
        fps = av_q2d(stream->avg_frame_rate);
    }else{
        fps = 30.0f;
    }
    
    //查找对应的解码器
     codec = avcodec_find_decoder(_codecCtx->codec_id);
    if(codec == NULL){
        printf("not find codec");
        return NO;
    }
    
    //打开
    if(avcodec_open2(_codecCtx, codec, NULL) < 0)
    {
        printf("open codec failed");
        return NO;
    }
    
    avFrame = av_frame_alloc();
    self.outputWidth = _codecCtx->width;
    self.outputHeight = _codecCtx->height;
    return YES;
    
}

- (BOOL)nextFrame
{
    int frameFinished = 0;
    AVPacket   *packet = av_packet_alloc();
    while (!frameFinished  && av_read_frame(_formateCtx, packet) >= 0) {
        if(packet->stream_index == videoStream_index){
            avcodec_decode_video2(_codecCtx, avFrame, &frameFinished, packet);
            av_packet_unref(packet);
        }
    }
   
    av_packet_free(&packet);
    
    if(frameFinished == 0){
//        av_free(_codecCtx);
//        av_free(_formateCtx);
//        avFrame = NULL;
    }
    
    return frameFinished != 0;
}

//- (UIImage *)getNextFrame
//{
//    float   picWidth;
//    float   picHeight;
//    AVPicture   picture;
//    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, _outputWidth, _outputHeight);
//
//    struct SwsContext * swsContext = sws_getContext(avFrame->width,
//                                                       avFrame->height,
//                                              AV_PIX_FMT_YUV420P,
//                                                       _outputWidth,    _outputHeight,
//                                                       AV_PIX_FMT_RGB24,
//                                                       SWS_FAST_BILINEAR,
//                                                       NULL,
//                                                       NULL,
//                                                       NULL);
//    if(swsContext == NULL){
//        return nil;
//    }
//    sws_scale(swsContext, avFrame->data, avFrame->linesize, 0, avFrame->height, picture.data, picture.linesize);
//    sws_freeContext(swsContext);
//
//    CGColorSpaceRef  spaceRef = CGColorSpaceCreateDeviceRGB();
//    CGBitmapInfo  bitMapInfo = kCGBitmapByteOrderDefault;
//    CFDataRef dataRef = CFDataCreate(kCFAllocatorDefault, picture.data[0], picture.linesize[0]);
//    CGDataProviderRef  providerRef = CGDataProviderCreateWithCFData(dataRef);
//    CGImageRef  imageRef = CGImageCreate(_outputWidth, _outputHeight, 8, 24, picture.linesize[0], spaceRef, bitMapInfo, providerRef, NULL, NO, kCGRenderingIntentDefault);
//    UIImage  *image = [[UIImage alloc] initWithCGImage:imageRef];
//    return image;
//
//}

- (void)nextDisplayFrame
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CG_Frame_YUV * yuvFrame = [self displayFrame];
        if([self.delegate respondsToSelector:@selector(updateDisplayFrame:)]){
            [self.delegate updateDisplayFrame:yuvFrame];
        }
    });
}
-(UIImage *)currentImage {
    if (!avFrame->data[0]) return nil;
   
    return [self imageFromAVPicture];
}
- (UIImage *)imageFromAVPicture
{
    AVPicture   picture;
   //
    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, _outputWidth, _outputHeight);

    struct SwsContext * imgConvertCtx = sws_getContext(avFrame->width,
                                                       avFrame->height,
                                                       AV_PIX_FMT_YUV420P,
                                                       _outputWidth,
                                                       _outputHeight,
                                                       AV_PIX_FMT_RGB24,
                                                       SWS_FAST_BILINEAR,
                                                       NULL,
                                                       NULL,
                                                       NULL);
    if(imgConvertCtx == nil){
        printf("SwsContext is null");
        return nil;
    }
    sws_scale(imgConvertCtx,
              avFrame->data,
              avFrame->linesize,
              0,
              avFrame->height,
              picture.data,
              picture.linesize);
    sws_freeContext(imgConvertCtx);
   
  
    //[UIImage imageWithCGImage:[self CGImageRefFromAVPicture:picture width:_outputWidth height:_outputHeight]]
    
//    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
//    CFDataRef data = CFDataCreate(kCFAllocatorDefault,
//                                  picture.data[0],
//                                  picture.linesize[0] * _outputHeight);
//
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGImageRef cgImage = CGImageCreate(_outputWidth,
//                                       _outputHeight,
//                                       8,
//                                       24,
//                                       picture.linesize[0],
//                                       colorSpace,
//                                       bitmapInfo,
//                                       provider,
//                                       NULL,
//                                       NO,
//                                       kCGRenderingIntentDefault);
     avpicture_free(&picture);
    return nil;
}

- (CG_Frame_YUV *)displayFrame
{
    CG_Frame_YUV *yuvFrame = [[CG_Frame_YUV alloc] init];
    yuvFrame.luma =  copyDecodedFrame(avFrame->data[0], _codecCtx->width, _codecCtx->height, avFrame->linesize[0]);
    yuvFrame.chromaB = copyDecodedFrame(avFrame->data[1], _codecCtx->width / 2.0f ,  _codecCtx->height / 2.0f, avFrame->linesize[1]);
    yuvFrame.chromaR = copyDecodedFrame(avFrame->data[2], _codecCtx->width / 2.0f, _codecCtx->height / 2.0f, avFrame->linesize[2]);
    
    yuvFrame.width = _codecCtx->width;
    yuvFrame.height = _codecCtx->height;
    return yuvFrame;
}

static NSData * copyDecodedFrame(unsigned char  *src,int width,int height,int linese)
{
    width = MIN(linese, width);
    NSMutableData * data = [NSMutableData dataWithLength:width * height];
    Byte * byts = data.mutableBytes;
    for (NSInteger i = 0 ; i<height; i++) {
        memcpy(byts, src, width);
        byts += width;
        src += linese;
    }
    return data;
}
@end
