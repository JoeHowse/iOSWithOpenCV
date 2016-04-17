//
//  VideoCamera.h
//  BeanCounter
//
//  Created by Joseph Howse on 2015-12-11.
//  Copyright © 2015 Nummist Media Corporation Limited. All rights reserved.
//

#import <opencv2/videoio/cap_ios.h>


@interface VideoCamera : CvVideoCamera

@property BOOL letterboxPreview;

- (void)setPointOfInterestInParentViewSpace:(CGPoint)point;

@end
