//
//  GARenderView.m
//  GAFFmpegDemo
//
//  Created by XDS on 2018/1/30.
//  Copyright © 2018年 MountainX. All rights reserved.
//http://blog.csdn.net/u013467442/article/details/44498125 ---opengl 一些入门的blog
// http://blog.csdn.net/kesalin/article/details/8221393 ----基本使用参数
//https://www.cnblogs.com/elvisyzhao/p/3398250.html
//http://blog.csdn.net/wangyuchun_799/article/details/7736928   ---- OpenGL ES入门详解
//http://blog.csdn.net/tyuiof/article/details/52754300  ---介绍shader opengles
//http://blog.csdn.net/goodtalent/article/details/53138338 --- opengles  三种变量 修饰
//https://www.cnblogs.com/salam/archive/2015/11/05/4937957.html  --- shader 编程
//http://blog.csdn.net/ylbs110/article/details/52074826

#import "GARenderView.h"
#include <OpenGLES/ES2/gl.h>

//加载编译 shader
GLint  LoadShader(GLenum shadetype ,const char *shaderSrc)
{
    GLuint   shader;
    
    shader = glCreateShader(shadetype);//创建shader program  if sucss retrun 0
    if(shader == 0){
        return 0;
    }
   const  GLchar * shader_src = (GLchar *)shaderSrc;
    glShaderSource(shader, 1, &shader_src, NULL);
    glCompileShader(shader);
#ifdef DEBUG
    
    GLint logLength;
    
//    　日志信息
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 1){
        char *infoLog = malloc(sizeof(char) * logLength);
        glGetShaderInfoLog(shader, logLength, NULL, infoLog);
        printf("%s",infoLog);
        free(infoLog);
    }
#endif
     GLint status;
     glGetShaderiv(shader, GL_COMPILE_STATUS, &status);//获取编译状态的shader‘ 信息
    if(status == 0){
        printf("shader compile failed");
        return 0;
    }
    return  shader;
}


@interface GARenderView()
{
    EAGLContext   *_EAContxt;
    GLuint         _frameBuffer;//帧缓冲区
    GLuint         _renderBuffer;//渲染缓冲区
    
    //绘制缓冲区的 宽度 高度
    GLint         _getRenderWidth;
    GLint         _getRenderHeight;
    
}

@end

@implementation GARenderView


+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        CAEAGLLayer *layer =(CAEAGLLayer *)self.layer;
        layer.opaque = YES;
        layer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@(NO),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
        _EAContxt =[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        [EAGLContext setCurrentContext:_EAContxt];
        
        //生成 绑定framebuffer 和 renderbuffer
        glGenFramebuffers(1, &_frameBuffer);//第一个参数是表示申请几个buffer 的空 不能写成0  0 是分配给OpenGLES 的
        glBindBuffer(GL_FRAMEBUFFER, _frameBuffer);
       
        
        glGenRenderbuffers(1, &_renderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        //分配buffer 存储空间
        [_EAContxt renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
        
        //将renderbuffer 装配到gl_color_attenment0 上
         glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
        
        //获取 绘制缓冲区的 宽高
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_getRenderWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT,&_getRenderHeight);
        
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            
            self = nil;
            return nil;
        }
        
        //添加shader
        [self addShader];
    }
    return self;
}

- (void)addShader
{
    GLuint   vertexShader,fragmentShader;
    vertexShader = LoadShader(GL_VERTEX_SHADER, <#const char *shaderSrc#>)
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
