//
//  ViewController.m
//  GAFFmpegDemo
//
//  Created by XDS on 2018/1/25.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import "ViewController.h"
#import "GACodec.h"
#import "CodeDecoder.h"
#import "CG_Frame_YUV.h"
#import "GARenderView.h"



@interface ViewController ()<GACodecDelegat>
{
    GACodec       *gaCodec;
    CodeDecoder   *coDec;
    UIImageView  *imageV;
    GARenderView * rendView;
}
@property (weak, nonatomic) IBOutlet UIImageView *playImageView;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    [self.playImageView removeFromSuperview];
    GACodec  *codec1 = [[GACodec alloc] initWithVideo:@"/Users/xds/Desktop/曹高安项目/GAFFmpegDemo/GAFFmpegDemo/source/video.mp4"];
    codec1.delegate  = self;
    gaCodec = codec1;
//    coDec = [[CodeDecoder alloc] init];
//    [coDec openWithPath:@"/Users/xds/Desktop/曹高安项目/GAFFmpegDemo/11.mp4"];

    
    [NSTimer scheduledTimerWithTimeInterval: 1 / 30.0f
                                     target:self
                                   selector:@selector(displayNextFrame:)
                                   userInfo:nil
                                    repeats:YES];
    //[coDec decodecFrame];
    rendView = [[GARenderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    rendView.backgroundColor = [UIColor redColor];
    [self.view addSubview:rendView];
    
    
}
- (void)updateDisplayFrame:(CG_Frame_YUV *)yuvFrame
{
   // NSLog(@"data1:%@",yuvFrame.luma);
    [rendView renderFrame:yuvFrame];
}
- (void)displayNextFrame:(NSTimer *)timer
{
    if(![gaCodec nextFrame]){
        return;
    }
    
    [gaCodec nextDisplayFrame];
    //获取 avframe 中数据转化为image】
   // UIImage *img = [gaCodec imageFromAVPicture];
//     _playImageView.image = gaCodec.currentImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
