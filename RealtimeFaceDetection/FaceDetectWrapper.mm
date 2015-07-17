//
//  FaceDetectWrapper.m
//  RealtimeFaceDetection
//


#import "FaceDetectWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>

@interface FaceDetectWrapper()
{
    cv::CascadeClassifier cascade;
}
@end

@implementation FaceDetectWrapper: NSObject

//cascade fileを読み込み
- (id)init {
    self = [super init];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    std::string fileName = (char *)[path UTF8String];
    
    if(!cascade.load(fileName)) {
        return nil;
    }
    
    return self;
}


- (UIImage *)recognize:(UIImage *)image {

    //UIImage -> Mat　への変換処理
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    cv::Mat mat(height, width, CV_8UC4);
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                    width,
                                                    height,
                                                    8,
                                                    mat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(contextRef);

    //検出した顔の位置情報を格納
    std::vector<cv::Rect> faces;
    //実際の検出処理
    cascade.detectMultiScale(mat,faces,1.1, 2,CV_HAAR_SCALE_IMAGE,cv::Size(30, 30));
    
    //検出した顔の位置情報を取得して四角を描く
    std::vector<cv::Rect>::const_iterator r = faces.begin();
    for(; r != faces.end(); ++r) {
        int width = cv::saturate_cast<int>(r->width);
        int height = cv::saturate_cast<int>(r->height);
        int x = cv::saturate_cast<int>(r->x);
        int y = cv::saturate_cast<int>(r->y);
        cv::rectangle(mat, cv::Point(x,y), cv::Point(x+width,y+height),cv::Scalar(250,0,0), 1, 4);
    }
    
    // Mat -> UIImage への変換処理
    UIImage *newImage = MatToUIImage(mat);
    return newImage;
}

@end
