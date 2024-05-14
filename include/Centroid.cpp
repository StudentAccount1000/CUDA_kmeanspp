#ifndef CENTROID_CPP
#define CENTROID_CPP

#include "Centroid.h"

Centroid::Centroid() 
    : DataPoint()
    , id(-1)
    , nPoints(0)
{
};

Centroid::Centroid(const double x, const double y) 
    : DataPoint(x, y)
    , id(-1)
    , nPoints(0)
{
};

double Centroid::distance(const DataPoint& p) const
{
    return (p.x - x) * (p.x - x) + (p.y - y) * (p.y - y);
}

#endif // CENTROID_CPP