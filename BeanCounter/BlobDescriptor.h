//
//  BlobDescriptor.h
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-15.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#ifndef BLOB_DESCRIPTOR_H
#define BLOB_DESCRIPTOR_H

#include <opencv2/core.hpp>

class BlobDescriptor
{
public:
    BlobDescriptor(const cv::Mat &normalizedHistogram, const cv::Mat &keypointDescriptors, uint32_t label);
    
    const cv::Mat &getNormalizedHistogram() const;
    const cv::Mat &getKeypointDescriptors() const;
    uint32_t getLabel() const;
    
private:
    cv::Mat normalizedHistogram;
    cv::Mat keypointDescriptors;
    uint32_t label;
};

#endif // !BLOB_DESCRIPTOR_H
