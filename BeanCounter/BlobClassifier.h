//
//  BlobClassifier.h
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-10.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#ifndef BLOB_CLASSIFIER_H
#define BLOB_CLASSIFIER_H

#import "Blob.h"
#import "BlobDescriptor.h"

#include <opencv2/features2d.hpp>

class BlobClassifier
{
public:
    BlobClassifier();
    
    /**
     * Add a reference blob to the classification model.
     */
    void update(const Blob &referenceBlob);
    
    /**
     * Clear the classification model.
     */
    void clear();
    
    /**
     * Classify a blob that was detected in a scene.
     */
    void classify(Blob &detectedBlob) const;
    
private:
    BlobDescriptor createBlobDescriptor(const Blob &blob) const;
    float findDistance(const BlobDescriptor &detectedBlobDescriptor, const BlobDescriptor &referenceBlobDescriptor) const;
    
    /**
     * A feature detector and descriptor extractor.
     * It finds features in images.
     * Then, it creates descriptors of the features.
     */
    cv::Ptr<cv::Feature2D> featureDetectorAndDescriptorExtractor;
    
    /**
     * A descriptor matcher.
     * It matches features based on their descriptors.
     */
    cv::Ptr<cv::DescriptorMatcher> descriptorMatcher;
    
    /**
     * Descriptors of the reference blobs.
     */
    std::vector<BlobDescriptor> referenceBlobDescriptors;
};

#endif // !BLOB_CLASSIFIER_H
