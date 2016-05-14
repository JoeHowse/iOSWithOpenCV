//
//  FaceDetector.cpp
//  ManyMasks
//
//  Created by Joseph Howse on 2016-03-06.
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

#include "FaceDetector.h"
#include "GeomUtils.h"

#ifdef WITH_CLAHE
#define EQUALIZE(src, dst) clahe->apply(src, dst)
#else
#define EQUALIZE(src, dst) cv::equalizeHist(src, dst)
#endif

const double DETECT_HUMAN_FACE_SCALE_FACTOR = 1.4;
const int DETECT_HUMAN_FACE_MIN_NEIGHBORS = 4;
const int DETECT_HUMAN_FACE_RELATIVE_MIN_SIZE_IN_IMAGE = 0.25;

const double DETECT_HUMAN_EYE_SCALE_FACTOR = 1.2;
const int DETECT_HUMAN_EYE_MIN_NEIGHBORS = 2;
const int DETECT_HUMAN_EYE_RELATIVE_MIN_SIZE_IN_FACE = 0.1;

const double DETECT_CAT_FACE_SCALE_FACTOR = 1.4;
const int DETECT_CAT_FACE_MIN_NEIGHBORS = 6;
const int DETECT_CAT_FACE_RELATIVE_MIN_SIZE_IN_IMAGE = 0.2;

const double ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_X_IN_EYE = 0.5;
const double ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_Y_IN_EYE = 0.65;

const double ESTIMATE_HUMAN_LEFT_EYE_CENTER_RELATIVE_X_IN_FACE = 0.3;
const double ESTIMATE_HUMAN_RIGHT_EYE_CENTER_RELATIVE_X_IN_FACE = 1.0 - ESTIMATE_HUMAN_LEFT_EYE_CENTER_RELATIVE_X_IN_FACE;
const double ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_Y_IN_FACE = 0.4;

const double ESTIMATE_HUMAN_NOSE_RELATIVE_LENGTH_IN_FACE = 0.2;

const double ESTIMATE_CAT_LEFT_EYE_CENTER_RELATIVE_X_IN_FACE = 0.25;
const double ESTIMATE_CAT_RIGHT_EYE_CENTER_RELATIVE_X_IN_FACE = 1.0 - ESTIMATE_CAT_LEFT_EYE_CENTER_RELATIVE_X_IN_FACE;
const double ESTIMATE_CAT_EYE_CENTER_RELATIVE_Y_IN_FACE = 0.4;

const double ESTIMATE_CAT_NOSE_TIP_RELATIVE_X_IN_FACE = 0.5;
const double ESTIMATE_CAT_NOSE_TIP_RELATIVE_Y_IN_FACE = 0.75;

const cv::Scalar DRAW_HUMAN_FACE_COLOR(0, 255, 255); // Yellow
const cv::Scalar DRAW_CAT_FACE_COLOR(255, 255, 255); // White
const cv::Scalar DRAW_LEFT_EYE_COLOR(0, 0, 255); // Red
const cv::Scalar DRAW_RIGHT_EYE_COLOR(0, 255, 0); // Green
const cv::Scalar DRAW_NOSE_COLOR(255, 0, 0); // Blue

const int DRAW_RADIUS = 4;

FaceDetector::FaceDetector(const std::string &humanFaceCascadePath, const std::string &catFaceCascadePath, const std::string &humanLeftEyeCascadePath, const std::string &humanRightEyeCascadePath)
: humanFaceClassifier(humanFaceCascadePath)
, catFaceClassifier(catFaceCascadePath)
, humanLeftEyeClassifier(humanLeftEyeCascadePath)
, humanRightEyeClassifier(humanRightEyeCascadePath)
#ifdef WITH_CLAHE
, clahe(cv::createCLAHE())
#endif
{
}

void FaceDetector::detect(cv::Mat &image, std::vector<Face> &faces, double resizeFactor, bool draw)
{
    faces.clear();
    
    if (resizeFactor == 1.0) {
        equalize(image);
    } else {
        cv::resize(image, resizedImage, cv::Size(), resizeFactor, resizeFactor, cv::INTER_AREA);
        equalize(resizedImage);
    }
    
    // Detect human faces.
    std::vector<cv::Rect> humanFaceRects;
    int detectHumanFaceMinWidth = MIN(image.cols, image.rows) * DETECT_HUMAN_FACE_RELATIVE_MIN_SIZE_IN_IMAGE;
    cv::Size detectHumanFaceMinSize(detectHumanFaceMinWidth, detectHumanFaceMinWidth);
    humanFaceClassifier.detectMultiScale(equalizedImage, humanFaceRects, DETECT_HUMAN_FACE_SCALE_FACTOR, DETECT_HUMAN_FACE_MIN_NEIGHBORS, 0, detectHumanFaceMinSize);
    
    // Detect cat faces.
    std::vector<cv::Rect> catFaceRects;
    int detectCatFaceMinWidth = MIN(image.cols, image.rows) * DETECT_CAT_FACE_RELATIVE_MIN_SIZE_IN_IMAGE;
    cv::Size detectCatFaceMinSize(detectCatFaceMinWidth, detectCatFaceMinWidth);
    catFaceClassifier.detectMultiScale(equalizedImage, catFaceRects, DETECT_CAT_FACE_SCALE_FACTOR, DETECT_CAT_FACE_MIN_NEIGHBORS, 0, detectCatFaceMinSize);
    
    for (cv::Rect &humanFaceRect : humanFaceRects) {
        // Evaluate the human face.
        detectInnerComponents(image, faces, resizeFactor, draw, Human, humanFaceRect);
        
        // Discard cat faces that intersect the human face.
        // (The human face detector is more reliable.)
        catFaceRects.erase(std::remove_if(catFaceRects.begin(), catFaceRects.end(), [&humanFaceRect](cv::Rect &catFaceRect) {
            return GeomUtils::intersects(humanFaceRect, catFaceRect);
        }), catFaceRects.end());
    }
    
    for (cv::Rect &catFaceRect : catFaceRects) {
        // Evaluate the cat face.
        detectInnerComponents(image, faces, resizeFactor, draw, Cat, catFaceRect);
    }
}

void FaceDetector::equalize(const cv::Mat &image) {
    switch (image.channels()) {
        case 4:
            cv::cvtColor(image, equalizedImage, cv::COLOR_BGRA2GRAY);
            EQUALIZE(equalizedImage, equalizedImage);
            break;
        case 3:
            cv::cvtColor(image, equalizedImage, cv::COLOR_BGR2GRAY);
            EQUALIZE(equalizedImage, equalizedImage);
            break;
        default:
            // Assume the image is already grayscale.
            EQUALIZE(image, equalizedImage);
            break;
    }
}

void FaceDetector::detectInnerComponents(cv::Mat &image, std::vector<Face> &faces, double resizeFactor, bool draw, Species species, cv::Rect faceRect)
{
    cv::Range rowRange(faceRect.y, faceRect.y + faceRect.height);
    cv::Range colRange(faceRect.x, faceRect.x + faceRect.width);
    
    bool isHuman = (species == Human);
    
    cv::Mat equalizedFaceMat(equalizedImage, rowRange, colRange);
    
    cv::Rect leftEyeRect;
    cv::Rect rightEyeRect;
    
    cv::Point2f leftEyeCenter;
    cv::Point2f rightEyeCenter;
    cv::Point2f noseTip;
    
    if (isHuman) {
        int faceWidth = equalizedFaceMat.cols;
        int halfFaceWidth = faceWidth / 2;
        
        int eyeMinWidth = faceWidth * DETECT_HUMAN_EYE_RELATIVE_MIN_SIZE_IN_FACE;
        cv::Size eyeMinSize(eyeMinWidth, eyeMinWidth);
        
        // Try to detect the left eye.
        std::vector<cv::Rect> leftEyeRects;
        humanLeftEyeClassifier.detectMultiScale(equalizedFaceMat.colRange(0, halfFaceWidth), leftEyeRects, DETECT_HUMAN_EYE_SCALE_FACTOR, DETECT_HUMAN_EYE_MIN_NEIGHBORS, 0, eyeMinSize);
        if (leftEyeRects.size() > 0) {
            leftEyeRect = leftEyeRects[0];
            leftEyeCenter.x = leftEyeRect.x + ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_X_IN_EYE * leftEyeRect.width;
            leftEyeCenter.y = leftEyeRect.y + ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_Y_IN_EYE * leftEyeRect.height;
        } else {
            // Assume the left eye is in a typical location for a human.
            leftEyeCenter.x = ESTIMATE_HUMAN_LEFT_EYE_CENTER_RELATIVE_X_IN_FACE * faceRect.width;
            leftEyeCenter.y = ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_Y_IN_FACE * faceRect.height;
        }
        
        // Try to detect the right eye.
        std::vector<cv::Rect> rightEyeRects;
        humanRightEyeClassifier.detectMultiScale(equalizedFaceMat.colRange(halfFaceWidth, faceWidth), rightEyeRects, DETECT_HUMAN_EYE_SCALE_FACTOR, DETECT_HUMAN_EYE_MIN_NEIGHBORS, 0, eyeMinSize);
        if (rightEyeRects.size() > 0) {
            rightEyeRect = rightEyeRects[0];
            // Adjust the right eye rect to be relative to the whole face.
            rightEyeRect.x += halfFaceWidth;
            rightEyeCenter.x = rightEyeRect.x + ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_X_IN_EYE * rightEyeRect.width;
            rightEyeCenter.y = rightEyeRect.y + ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_Y_IN_EYE * rightEyeRect.height;
        } else {
            // Assume the right eye is in a typical location for a human.
            rightEyeCenter.x = ESTIMATE_HUMAN_RIGHT_EYE_CENTER_RELATIVE_X_IN_FACE * faceRect.width;
            rightEyeCenter.y = ESTIMATE_HUMAN_EYE_CENTER_RELATIVE_Y_IN_FACE * faceRect.height;
        }
        
        // Assume the nose is in a typical location for a human.
        // Consider the location of the eyes.
        cv::Point2f eyeDiff = rightEyeCenter - leftEyeCenter;
        cv::Point2f centerBetweenEyes = leftEyeCenter + 0.5 * eyeDiff;
        cv::Point2f noseNormal = cv::Point2f(-eyeDiff.y, eyeDiff.x) / sqrt(pow(eyeDiff.x, 2.0) + pow(eyeDiff.y, 2.0));
        double noseLength = ESTIMATE_HUMAN_NOSE_RELATIVE_LENGTH_IN_FACE * faceRect.height;
        noseTip = centerBetweenEyes + noseNormal * noseLength;
    }
    
    else {
        // I haz kitteh! The face is a cat.
        // Assume the eyes and nose are in typical locations for a cat.
        
        leftEyeCenter.x = ESTIMATE_CAT_LEFT_EYE_CENTER_RELATIVE_X_IN_FACE * faceRect.width;
        leftEyeCenter.y = ESTIMATE_CAT_EYE_CENTER_RELATIVE_Y_IN_FACE * faceRect.height;
        
        rightEyeCenter.x = ESTIMATE_CAT_RIGHT_EYE_CENTER_RELATIVE_X_IN_FACE * faceRect.width;
        rightEyeCenter.y = ESTIMATE_CAT_EYE_CENTER_RELATIVE_Y_IN_FACE * faceRect.height;
        
        noseTip.x = ESTIMATE_CAT_NOSE_TIP_RELATIVE_X_IN_FACE * faceRect.width;
        noseTip.y = ESTIMATE_CAT_NOSE_TIP_RELATIVE_Y_IN_FACE * faceRect.height;
    }
    
    // Restore everything to the original scale.
    
    faceRect.x /= resizeFactor;
    faceRect.y /= resizeFactor;
    faceRect.width /= resizeFactor;
    faceRect.height /= resizeFactor;
    
    rowRange.start /= resizeFactor;
    rowRange.end /= resizeFactor;
    
    colRange.start /= resizeFactor;
    colRange.end /= resizeFactor;
    
    cv::Mat faceMat(image, rowRange, colRange);
    
    leftEyeRect.x /= resizeFactor;
    leftEyeRect.y /= resizeFactor;
    leftEyeRect.width /= resizeFactor;
    leftEyeRect.height /= resizeFactor;
    
    rightEyeRect.x /= resizeFactor;
    rightEyeRect.y /= resizeFactor;
    rightEyeRect.width /= resizeFactor;
    rightEyeRect.height /= resizeFactor;
    
    leftEyeCenter /= resizeFactor;
    rightEyeCenter /= resizeFactor;
    noseTip /= resizeFactor;
    
    faces.push_back(Face(species, faceMat, leftEyeCenter, rightEyeCenter, noseTip));
    
    if (draw) {
        cv::rectangle(image, faceRect.tl(), faceRect.br(), isHuman ? DRAW_HUMAN_FACE_COLOR : DRAW_CAT_FACE_COLOR);
        cv::circle(image, faceRect.tl() + cv::Point(leftEyeCenter), DRAW_RADIUS, DRAW_LEFT_EYE_COLOR);
        cv::circle(image, faceRect.tl() + cv::Point(rightEyeCenter), DRAW_RADIUS, DRAW_RIGHT_EYE_COLOR);
        cv::circle(image, faceRect.tl() + cv::Point(noseTip), DRAW_RADIUS, DRAW_NOSE_COLOR);
        
        if (leftEyeRect.width > 0) {
            cv::rectangle(image, faceRect.tl() + leftEyeRect.tl(), faceRect.tl() + leftEyeRect.br(), DRAW_LEFT_EYE_COLOR);
        }
        if (rightEyeRect.width > 0) {
            cv::rectangle(image, faceRect.tl() + rightEyeRect.tl(), faceRect.tl() + rightEyeRect.br(), DRAW_RIGHT_EYE_COLOR);
        }
    }
}