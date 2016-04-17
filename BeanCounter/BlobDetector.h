//
//  BlobDetector.h
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-10.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#ifndef BLOB_DETECTOR_H
#define BLOB_DETECTOR_H

#include "Blob.h"

class BlobDetector
{
public:
    void detect(cv::Mat &image, std::vector<Blob> &blob, double resizeFactor = 1.0, bool draw = false);
    
    const cv::Mat &getMask() const;
    
private:
    void createMask(const cv::Mat &image);
    
    cv::Mat resizedImage;
    cv::Mat mask;
    cv::Mat edges;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
};

#endif // !BLOB_DETECTOR_H
