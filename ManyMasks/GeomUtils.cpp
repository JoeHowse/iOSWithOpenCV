//
//  GeomUtils.cpp
//  ManyMasks
//
//  Created by Joseph Howse on 2016-03-12.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#include "GeomUtils.h"

bool GeomUtils::intersects(const cv::Rect &rect0, const cv::Rect &rect1)
{
    return
        rect0.x                < rect1.x + rect1.width  &&
        rect0.x + rect0.width  > rect1.x                &&
        rect0.y                < rect1.y + rect1.height &&
        rect0.y + rect0.height > rect1.y;
}