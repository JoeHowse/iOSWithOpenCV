//
//  BlobClassifier.h
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-10.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  (1) Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//  (2) Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//  (3) Neither the name of the copyright holder nor the names of its
//      contributors may be used to endorse or promote products derived from
//      this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
//  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
//  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
     * An adaptive equalizer to enhance local contrast.
     */
    cv::Ptr<cv::CLAHE> clahe;
    
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
