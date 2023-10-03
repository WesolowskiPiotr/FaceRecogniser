//
//  OpenCVWrapper.h
//  FaceRecogniser
//
//  Created by Piotr Wesołowski on 03/10/2023.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (UIImage *)generateHistogramForImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END

