//
//  BlobClassifier.cpp
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-10.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
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

BlobClassifier::BlobClassifier() {
#ifdef WITH_OPENCV_CONTRIB
    featureDetectorAndDescriptorExtractor = cv::xfeatures2d::SURF::create();
    descriptorMatcher = cv::DescriptorMatcher::create("FlannBased");
#else
    featureDetectorAndDescriptorExtractor = cv::ORB::create();
    descriptorMatcher = cv::DescriptorMatcher::create("BruteForce-HammingLUT");
#endif
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
