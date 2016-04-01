//
//  FaceDetector.h
//  ManyMasks
//
//  Created by Joseph Howse on 2016-03-06.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#ifndef FACE_DETECTOR_H
#define FACE_DETECTOR_H

#include <opencv2/objdetect.hpp>

#include "Face.h"

class FaceDetector {

public:
    FaceDetector(const std::string &humanFaceCascadePath, const std::string &catFaceCascadePath, const std::string &humanLeftEyeCascadePath, const std::string &humanRightEyeCascadePath);
    
    void detect(const cv::Mat &image, std::vector<Face> &faces, double resizeFactor = 1.0, bool draw = false);
    
private:
    void equalize(const cv::Mat &image);
    void detectInnerComponents(const cv::Mat &image, std::vector<Face> &faces, double resizeFactor, bool draw, Species species, cv::Rect faceRect);
    
    cv::CascadeClassifier humanFaceClassifier;
    cv::CascadeClassifier catFaceClassifier;
    cv::CascadeClassifier humanLeftEyeClassifier;
    cv::CascadeClassifier humanRightEyeClassifier;
    
#ifdef WITH_CLAHE
    cv::Ptr<cv::CLAHE> clahe;
#endif
    
    cv::Mat resizedImage;
    cv::Mat equalizedImage;
};

#endif // !FACE_DETECTOR_H
