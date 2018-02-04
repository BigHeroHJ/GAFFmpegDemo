//
//  GARenderView.m
//  GAFFmpegDemo
//
//  Created by XDS on 2018/1/30.
//  Copyright © 2018年 MountainX. All rights reserved.
//https://learnopengl-cn.github.io/01%20Getting%20started/04%20Hello%20Triangle/ ---翻译OpenGL
//http://blog.csdn.net/u013467442/article/details/44498125 ---opengl 一些入门的blog
// http://blog.csdn.net/kesalin/article/details/8221393 ----基本使用参数
//https://www.cnblogs.com/elvisyzhao/p/3398250.html
//http://blog.csdn.net/wangyuchun_799/article/details/7736928   ---- OpenGL ES入门详解
//http://blog.csdn.net/tyuiof/article/details/52754300  ---介绍shader opengles
//http://blog.csdn.net/goodtalent/article/details/53138338 --- opengles  三种变量 修饰
//https://www.cnblogs.com/salam/archive/2015/11/05/4937957.html  --- shader 编程
//http://blog.csdn.net/ylbs110/article/details/52074826

#import "GARenderView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GACodec.h"
#import "CG_Frame_YUV.h"


#define shader 部分

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

///输入 -> | 顶点处理 -> 裁剪、图元组装 -> 光栅化 -> 图元处理 | -> 像素/
//整形，int
//浮点，float
//向量，vec4，vec3
//矩阵，mat4 mat2 mat3
//纹理单元，sampler2D sampler1D sampler3D
/**
uniform 修饰符 是全局的 所以变量名字不要重复
 attribute 只能在顶点着色器 中使用（vertex shader） 不能再外面使用其他fragment shader等使用
 glBindAttribLocation 外部使用 这个函数 绑定每个属性的 位置值  使用glVertexAttribPointer 个体属性赋值
 in  输入
 out 输出
 */

//顶点着色器 代码 一个shader 小程序
NSString *const vertexShaderString = SHADER_STRING
(
 //layout(location=0)
  attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = position;
     v_texcoord = texcoord;
 }
 );


//原图
const float colormatrix_lomo[] = {
    1.7f,  0.1f, 0.1f, 0, -73.1f,
    0,  1.7f, 0.1f, 0, -73.1f,
    0,  0.1f, 1.6f, 0, -73.1f,
    0,  0, 0, 1.0f, 0
};

//黑白
//const float colormatrix_heibai[] = {
//    0.8f,  1.6f, 0.2f, 0, -163.9f,
//    0.8f,  1.6f, 0.2f, 0, -163.9f,
//    0.8f,  1.6f, 0.2f, 0, -163.9f,
//    0,  0, 0, 1.0f, 0 };

//怀旧
const float colormatrix_huaijiu[] = {
    0.2f,0.5f, 0.1f, 0, 40.8f,
    0.2f, 0.5f, 0.1f, 0, 40.8f,
    0.2f,0.5f, 0.1f, 0, 40.8f,
    0, 0, 0, 1, 0 };


/**
 varying 修饰符 一般用于vertex 传递给fragment shader 的修饰使用  一般在定点中 修改 传递给fragment shader
 */
// 片段着色器代码 一个shader 小程序
NSString *const yuvFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 
 void main()
 {
    
     highp float y = texture2D(s_texture_y, v_texcoord).r;
     highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;
     highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
    highp float r_change = r * 0.8 + g * 1.6 + b * 0.2+ 1.0 ;
    highp float g_change = r * 0.8 + 1.6 +  b * 0.2 + 1.0 ;
    highp float b_change = 0.8  + g * 1.6 +  b * 0.2  + 1.0 ;
    highp float alp_change = r * 0.0 + g * 0.0 + b * 0.0 + 1.0 + 0.0 ;
     
     gl_FragColor = vec4(r,g,b,1.0);//设置的 fragcolor 就是输出的color
 }
 );



//加载编译 shader
GLint  LoadShader(GLenum shadetype ,NSString *shaderString)
{
    GLuint   shader;
    
    shader = glCreateShader(shadetype);//创建shader program  if sucss retrun 0
    if(shader == 0){
        return 0;
    }
    const GLchar *sources = (GLchar *)shaderString.UTF8String;
    glShaderSource(shader, 1, &sources, NULL);
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
    
    
    GLuint        _program;
    
    //uniform 变量的 位置index
    GLuint        _uniformMaterixIndex;
    
   // GLuint        _textures[3];
    GLuint          _textures[3];
    GLint         _uniformSamplers[3];

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
        if(!_EAContxt || ![EAGLContext setCurrentContext:_EAContxt])
        {
            return nil;
        }
        
        //生成 绑定framebuffer 和 renderbuffer
        glGenFramebuffers(1, &_frameBuffer);//第一个参数是表示申请几个buffer 的空 不能写成0  0 是分配给OpenGLES 的
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);

        glGenRenderbuffers(1, &_renderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        //分配buffer 存储空间
        [_EAContxt renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
        if (![_EAContxt renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer])
        {
            NSLog(@"attach渲染缓冲区失败");
        }
       
        //获取 绘制缓冲区的 宽高
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_getRenderWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT,&_getRenderHeight);
        
        //将renderbuffer 装配到gl_color_attenment0 上
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
        //分配空间
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        GLenum erro = glGetError();
        printf("error code %x",erro);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
         NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            //self = nil;
            return nil;
        }
        
        //添加shader
        [self addShader];
    
        
    }
    return self;
}

/**
 添加shader 着色器
*/
- (BOOL)addShader
{
    
    _program = glCreateProgram();//创建一个程序
    GLuint   vertexShader,fragmentShader;//顶点着色器（存储顶点数据） 和 片段着色器 （输出color）
    vertexShader = LoadShader(GL_VERTEX_SHADER, vertexShaderString);
    fragmentShader = LoadShader(GL_FRAGMENT_SHADER, yuvFragmentShaderString);
    if(!vertexShader ||!fragmentShader)
    {
        printf("vertex & fragment is failed");
        return NO;
    }
    
    //连接shader 到program
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    
    //绑定顶点属性 绑定索引到顶点属性
    glBindAttribLocation(_program, 0, "position");//绑定属性值 也可以通过layout(location=0) 在shader 程序的属性之前
    //参数是指在 shader program 中 第一个 名为position的属性
    glBindAttribLocation(_program, 1, "texcoord");
    //连接程序
    glLinkProgram(_program);
    
    //获取程序program status
    GLint  status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if(status == GL_FALSE){
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"<<<<着色器连接失败 %@>>>", messageString);
        return NO;
    }
    _uniformMaterixIndex = glGetUniformLocation(_program, "modelViewProjectionMatrix");
   
    GLint result;
    //下面都是获取program 信息 是否可用啥的
     glValidateProgram(_program);
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0){
        return NO;
    }
#endif
    glGetProgramiv(_program, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
        return NO;
    }
    if(vertexShader)
        glDeleteShader(vertexShader);
    if(fragmentShader)
        glDeleteShader(fragmentShader);
    
    
   
    return YES;
}

- (void)renderFrame:(CG_Frame_YUV *)frame
{
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    [EAGLContext setCurrentContext:_EAContxt];
   // glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glViewport(0, 0, _getRenderWidth, _getRenderHeight);//窗口大小
//    glClearColor(0.25, 0.5, 0.5, 1);//清除背景色 黑色
//    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(_program);//使用 shader program
    if(frame)
    {
        
        [self setYUVFrame:frame];
    }
     [self getAttriFragmentShaderWithProgram:_program];//
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

    [self render];//渲染 renderbuffer
    
}

-(void)render{
    
    //设置上下文
    [EAGLContext setCurrentContext:_EAContxt];
    
    CGSize size = self.bounds.size;
    
    /*
     我们如果选定(0, 0), (0, 1), (1, 0), (1, 1)四个纹理坐标的点对纹理图像映射的话，就是映射的整个纹理图片。如果我们选择(0, 0), (0, 1), (0.5, 0), (0.5, 1) 四个纹理坐标的点对纹理图像映射的话，就是映射左半边的纹理图片（相当于右半边图片不要了），相当于取了一张320x480的图片。但是有一点需要注意，映射的纹理图片不一定是“矩形”的。实际上可以指定任意形状的纹理坐标进行映射。下面这张图就是映射了一个梯形的纹理到目标物体表面。这也是纹理（Texture）比上一篇文章中记录的表面（Surface）更加灵活的地方。
     */
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    
    static const GLfloat coordVertices[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    //指定第一个顶点 size 是2 （position {x,y}）
    
    //两种指定 属性索引的函数
    //        glVertexAttribIPointer();
    //        glVertexAttribIPointer(<#GLuint index#>, <#GLint size#>, <#GLenum type#>, <#GLsizei stride#>, <#const GLvoid *pointer#>)
    //更新属性值
    glVertexAttribPointer(0, 2, GL_FLOAT, 0, 0, squareVertices);
    //开启定点属性数组
    glEnableVertexAttribArray(0);
    
    
    glVertexAttribPointer(1, 2, GL_FLOAT, 0, 0, coordVertices);
    glEnableVertexAttribArray(1);
    
    //绘制
    
    //当采用顶点数组方式绘制图形时，使用该函数。该函数根据顶点数组中的坐标数据和指定的模式，进行绘制。
    //绘制方式,从数组的哪一个点开始绘制(一般为0),顶点个数
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //将该渲染缓冲区对象绑定到管线上
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    //把缓冲区（render buffer和color buffer）的颜色呈现到UIView上
    [_EAContxt presentRenderbuffer:GL_RENDERBUFFER];
    
}
- (void)getAttriFragmentShaderWithProgram:(GLint)program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
    //对几个纹理采样器变量进行设置
    glUniform1i(_uniformSamplers[0], 0);
    glUniform1i(_uniformSamplers[1], 1);
    glUniform1i(_uniformSamplers[2], 2);
    
}
- (void)setYUVFrame:(CG_Frame_YUV *)frame{
    
    NSInteger frameWidth = frame.width;
    NSInteger frameHeight =  frame.height;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);//四字节对齐
    
    if(_textures[0] == 0){
        glGenTextures(3, _textures);
    }
    //数组 得到 每个yuv 数据 对应的 存储
    const UInt8 * pixels[3] = {frame.luma.bytes,frame.chromaB.bytes,frame.chromaR.bytes};
    const int widths[3] = {frame.width,frame.width / 2.0f,frame.width / 2.0f};
    const int heights[3] = {frame.height,frame.height / 2.0f,frame.height / 2.0f};

    //for 循环绑定yuv 纹理数据
    for (int i = 0; i < 3; i++) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, widths[i], heights[i], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
