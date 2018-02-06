//
//  GAMedioPlayController.m
//  GAFFmpegDemo
//
//  Created by XDS on 2018/2/6.
//  Copyright © 2018年 MountainX. All rights reserved.
// test GAMediaCodec

#import "GAMedioPlayController.h"
#import "GAMediaCodec.h"
#import "CG_Frame_YUV.h"
#import "GARenderView.h"


#define MIN_DURATION 0.1

@interface GAMedioPlayController ()
{
    GAMediaCodec  *codec;
    float         _videoPfs;
    
    float         _playWidth;//播放时的 宽高
    float         _playHeight;
    
    NSMutableArray *_aviliableFrames;//用于解码足够播放的frames存放
    
    dispatch_queue_t     _decoderQueue;
    
    
    float         _bufferDuration;//解码出来的所有的时间
    
    GARenderView *playView; //opengl 显示yuv

}

@property (nonatomic, assign) BOOL isDecoding;//正在解码
@property (nonatomic, assign) BOOL isPlaying;//playing
@end

@implementation GAMedioPlayController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    _bufferDuration = 0.0f;
    
    //同步队列
    _decoderQueue = dispatch_queue_create("codecPlay", DISPATCH_QUEUE_SERIAL);
    
    _aviliableFrames = [NSMutableArray array];
    
    codec = [[GAMediaCodec alloc] initWithSourcePath:@"/Users/xds/Desktop/曹高安项目/GAFFmpegDemo/GAFFmpegDemo/source/video.mp4"];
    
    _playWidth = codec.outputWidth;
    _playHeight = codec.outputHeight;
    
    _videoPfs = codec.fps;//
    
    playView = [[GARenderView alloc] init];
    playView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * _playHeight / _playWidth);
    playView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:playView];
    
    [self asyncDecodeFrame];
    
    //延时一个 0.1 秒 先去解码
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1), dispatch_get_main_queue(), ^{
        self.isPlaying = YES;
        [self tick];
    });
    
}

- (void)tick
{
    if(_isDecoding && _bufferDuration > MIN_DURATION){
        _isDecoding = NO;
    }
    
    [self asyncDecodeFrame];
    CGFloat interval = 0;
    if(_bufferDuration > MIN_DURATION){
      interval =  [self playFrame];
    }
    
    //const NSTimeInterval correction = [self tickCorrection];
    //const NSTimeInterval time = MAX(interval + correction, 0.01);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });
    
}
- (void)asyncDecodeFrame
{
    if(self.isDecoding)
        return;
    
    self.isDecoding = YES;
    
    CGFloat  duration = MIN_DURATION;//设置最小的 缓冲解码时间
    
    __weak typeof(self) weakSelf = self;
    //在新开的 同步队列中去 获取frames
    dispatch_async(_decoderQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(codec){
            NSArray * addFrames = [codec decodeFrame:duration];
            if(addFrames.count){
                [strongSelf addFrames:addFrames];
            }
        }
    });
}
- (void)addFrames:(NSArray *)frames
{
    for (CG_Frame_YUV * fram in frames) {
        [_aviliableFrames addObject:fram];
        _bufferDuration += fram.duration;
    }
}
- (int)playFrame
{
    CGFloat interTime = 0;
    CG_Frame_YUV * frame = NULL;
    if (_aviliableFrames.count > 0) {
        frame = _aviliableFrames[0];
        [_aviliableFrames removeObjectAtIndex:0];
        _bufferDuration -= frame.duration;
    }
    if(frame){
     // [playView renderFrame:frame];
    }
    return  interTime = frame.duration;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
