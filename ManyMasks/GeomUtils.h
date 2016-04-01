//
//  GeomUtils.h
//  ManyMasks
//
//  Created by Joseph Howse on 2016-03-12.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#ifndef GEOM_UTILS_H
#define GEOM_UTILS_H

#include <opencv2/core.hpp>

namespace GeomUtils {
    bool intersects(const cv::Rect &rect0, const cv::Rect &rect1);
}

#endif // !GEOM_UTILS_H
