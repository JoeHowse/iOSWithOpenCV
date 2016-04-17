//
//  Blob.cpp
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-09.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#import "Blob.h"

Blob::Blob(const cv::Mat &mat, uint32_t label)
: label(label)
{
    mat.copyTo(this->mat);
}

Blob::Blob() {
}

Blob::Blob(const Blob &other)
: label(other.label)
{
    other.mat.copyTo(mat);
}

bool Blob::isEmpty() const {
    return mat.empty();
}

uint32_t Blob::getLabel() const {
    return label;
}

void Blob::setLabel(uint32_t value) {
    label = value;
}

const cv::Mat &Blob::getMat() const {
    return mat;
}

int Blob::getWidth() const {
    return mat.cols;
}

int Blob::getHeight() const {
    return mat.rows;
}
