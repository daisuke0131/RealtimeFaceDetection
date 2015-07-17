//
//  FaceDetectorWrapper.h
//  RealtimeFaceDetection
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FaceDetectWrapper: NSObject

- (id)init;
- (UIImage *)recognize:(UIImage *)image;

@end