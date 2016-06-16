//
//  BlobClassifier.cpp
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

#include <opencv2/imgproc.hpp>

#include "BlobClassifier.h"

#ifdef WITH_OPENCV_CONTRIB
#include <opencv2/xfeatures2d.hpp>
#endif

const int HISTOGRAM_NUM_BINS_PER_CHANNEL = 32;
const int HISTOGRAM_COMPARISON_METHOD = cv::HISTCMP_CHISQR_ALT;

const float HISTOGRAM_DISTANCE_WEIGHT = 0.98f;
const float KEYPOINT_MATCHING_DISTANCE_WEIGHT = 1.0f - HISTOGRAM_DISTANCE_WEIGHT;

BlobClassifier::BlobClassifier()
: clahe(cv::createCLAHE())
#ifdef WITH_OPENCV_CONTRIB
, featureDetectorAndDescriptorExtractor(cv::xfeatures2d::SURF::create())
, descriptorMatcher(cv::DescriptorMatcher::create("FlannBased"))
#else
, featureDetectorAndDescriptorExtractor(cv::ORB::create())
, descriptorMatcher(cv::DescriptorMatcher::create("BruteForce-HammingLUT"))
#endif
{
}

void BlobClassifier::update(const Blob &referenceBlob) {
    referenceBlobDescriptors.push_back(createBlobDescriptor(referenceBlob));
}

void BlobClassifier::clear() {
    referenceBlobDescriptors.clear();
}

void BlobClassifier::classify(Blob &detectedBlob) const {
    BlobDescriptor detectedBlobDescriptor = createBlobDescriptor(detectedBlob);
    float bestDistance = FLT_MAX;
    uint32_t bestLabel = 0;
    for (const BlobDescriptor &referenceBlobDescriptor : referenceBlobDescriptors) {
        float distance = findDistance(detectedBlobDescriptor, referenceBlobDescriptor);
        if (distance < bestDistance) {
            bestDistance = distance;
            bestLabel = referenceBlobDescriptor.getLabel();
        }
    }
    detectedBlob.setLabel(bestLabel);
}

BlobDescriptor BlobClassifier::createBlobDescriptor(const Blob &blob) const {
    
    const cv::Mat &mat = blob.getMat();
    int numChannels = mat.channels();
    
    // Calculate the histogram of the blob's image.
    cv::Mat histogram;
    int channels[] = { 0, 1, 2 };
    int numBins[] = { HISTOGRAM_NUM_BINS_PER_CHANNEL, HISTOGRAM_NUM_BINS_PER_CHANNEL, HISTOGRAM_NUM_BINS_PER_CHANNEL };
    float range[] = { 0.0f, 256.0f };
    const float *ranges[] = { range, range, range };
    cv::calcHist(&mat, 1, channels, cv::Mat(), histogram, 3, numBins, ranges);
    
    // Normalize the histogram.
    histogram *= (1.0f / (mat.rows * mat.cols));
    
    // Convert the blob's image to grayscale.
    cv::Mat grayMat;
    switch (numChannels) {
        case 4:
            cv::cvtColor(mat, grayMat, cv::COLOR_BGRA2GRAY);
            break;
        default:
            cv::cvtColor(mat, grayMat, cv::COLOR_BGR2GRAY);
            break;
    }
    
    // Adaptively equalize the grayscale image to enhance local contrast.
    clahe->apply(grayMat, grayMat);
    
    // Detect features in the grayscale image.
    std::vector<cv::KeyPoint> keypoints;
    featureDetectorAndDescriptorExtractor->detect(grayMat, keypoints);
    
    // Extract descriptors of the features.
    cv::Mat keypointDescriptors;
    featureDetectorAndDescriptorExtractor->compute(grayMat, keypoints, keypointDescriptors);
    
    return BlobDescriptor(histogram, keypointDescriptors, blob.getLabel());
}

float BlobClassifier::findDistance(const BlobDescriptor &detectedBlobDescriptor, const BlobDescriptor &referenceBlobDescriptor) const {
    
    // Calculate the histogram distance.
    float histogramDistance = (float)cv::compareHist(detectedBlobDescriptor.getNormalizedHistogram(), referenceBlobDescriptor.getNormalizedHistogram(), HISTOGRAM_COMPARISON_METHOD);
    
    // Calculate the keypoint matching distance.
    float keypointMatchingDistance = 0.0f;
    std::vector<cv::DMatch> keypointMatches;
    descriptorMatcher->match(detectedBlobDescriptor.getKeypointDescriptors(), referenceBlobDescriptor.getKeypointDescriptors(), keypointMatches);
    for (const cv::DMatch &keypointMatch : keypointMatches) {
        keypointMatchingDistance += keypointMatch.distance;
    }
    
    return histogramDistance * HISTOGRAM_DISTANCE_WEIGHT + keypointMatchingDistance * KEYPOINT_MATCHING_DISTANCE_WEIGHT;
}
