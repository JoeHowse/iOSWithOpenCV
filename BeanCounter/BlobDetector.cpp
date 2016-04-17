//
//  BlobDetector.cpp
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-10.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#include <opencv2/imgproc.hpp>

#include "BlobDetector.h"

const double MASK_STD_DEVS_FROM_MEAN = 1.0;
const double MASK_EROSION_KERNEL_RELATIVE_SIZE_IN_IMAGE = 0.005;
const int MASK_NUM_EROSION_ITERATIONS = 8;

const double BLOB_RELATIVE_MIN_SIZE_IN_IMAGE = 0.05;

const cv::Scalar DRAW_RECT_COLOR(0, 255, 0); // Green

void BlobDetector::detect(cv::Mat &image, std::vector<Blob> &blobs, double resizeFactor, bool draw)
{
    blobs.clear();
    
    if (resizeFactor == 1.0) {
        createMask(image);
    } else {
        cv::resize(image, resizedImage, cv::Size(), resizeFactor, resizeFactor, cv::INTER_AREA);
        createMask(resizedImage);
    }
    
    // Find the edges in the mask.
    cv::Canny(mask, edges, 191, 255);
    
    // Find the contours of the edges.
    cv::findContours(edges, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
    
    std::vector<cv::Rect> rects;
    int blobMinSize = (int)(MIN(image.rows, image.cols) * BLOB_RELATIVE_MIN_SIZE_IN_IMAGE);
    for (std::vector<cv::Point> contour : contours) {
        
        // Find the contour's bounding rectangle.
        cv::Rect rect = cv::boundingRect(contour);
        
        // Restore the bounding rectangle to the original scale.
        rect.x /= resizeFactor;
        rect.y /= resizeFactor;
        rect.width /= resizeFactor;
        rect.height /= resizeFactor;
        
        if (rect.width < blobMinSize || rect.height < blobMinSize) {
            continue;
        }
        
        // Create the blob from the sub-image inside the bounding rectangle.
        blobs.push_back(Blob(cv::Mat(image, rect)));
        
        // Remember the bouning rectangle in order to draw it later.
        rects.push_back(rect);
    }
    
    if (draw) {
        // Draw the bounding rectangles.
        for (const cv::Rect &rect : rects) {
            cv::rectangle(image, rect.tl(), rect.br(), DRAW_RECT_COLOR);
        }
    }
}

const cv::Mat &BlobDetector::getMask() const {
    return mask;
}

void BlobDetector::createMask(const cv::Mat &image) {
    
    // Find the image's mean color.
    // Presumably, this is the background color.
    // Also find the standard deviation.
    cv::Scalar meanColor;
    cv::Scalar stdDevColor;
    cv::meanStdDev(image, meanColor, stdDevColor);
    
    // Create a mask based on a range around the mean color.
    cv::Scalar halfRange = MASK_STD_DEVS_FROM_MEAN * stdDevColor;
    cv::Scalar lowerBound = meanColor - halfRange;
    cv::Scalar upperBound = meanColor + halfRange;
    cv::inRange(image, lowerBound, upperBound, mask);
    
    // Erode the mask to merge neighboring blobs.
    int kernelWidth = (int)(MIN(image.cols, image.rows) * MASK_EROSION_KERNEL_RELATIVE_SIZE_IN_IMAGE);
    if (kernelWidth > 0) {
        cv::Size kernelSize(kernelWidth, kernelWidth);
        cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, kernelSize);
        cv::erode(mask, mask, kernel, cv::Point(-1, -1), MASK_NUM_EROSION_ITERATIONS);
    }
}
