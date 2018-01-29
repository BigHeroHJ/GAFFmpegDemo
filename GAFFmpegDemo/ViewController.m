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

@interface ViewController ()
{
    GACodec       *gaCodec;
    CodeDecoder   *coDec;
    UIImageView  *imageV;
}
@property (weak, nonatomic) IBOutlet UIImageView *playImageView;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  

    GACodec  *codec1 = [[GACodec alloc] initWithVideo:@"/Users/lemonholl/Downloads/9533522808.f4v.mp4"];
    
    gaCodec = codec1;
//    coDec = [[CodeDecoder alloc] init];
//    [coDec openWithPath:@"/Users/xds/Desktop/曹高安项目/GAFFmpegDemo/11.mp4"];

    
    [NSTimer scheduledTimerWithTimeInterval: 1 / 30.0f
                                     target:self
                                   selector:@selector(displayNextFrame:)
                                   userInfo:nil
                                    repeats:YES];
    //[coDec decodecFrame];
}
- (void)displayNextFrame:(NSTimer *)timer
{
    if(![gaCodec nextFrame]){
        return;
    }
   
    //获取 avframe 中数据转化为image】
   // UIImage *img = [gaCodec imageFromAVPicture];
     _playImageView.image = gaCodec.currentImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
