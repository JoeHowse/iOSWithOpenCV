//
//  BlobDescriptor.cpp
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-15.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#include "BlobDescriptor.h"

BlobDescriptor::BlobDescriptor(const cv::Mat &normalizedHistogram, const cv::Mat &keypointDescriptors, uint32_t label)
: normalizedHistogram(normalizedHistogram)
, keypointDescriptors(keypointDescriptors)
, label(label)
{
}

const cv::Mat &BlobDescriptor::getNormalizedHistogram() const {
    return normalizedHistogram;
}

const cv::Mat &BlobDescriptor::getKeypointDescriptors() const {
    return keypointDescriptors;
}

uint32_t BlobDescriptor::getLabel() const {
    return label;
}
