#ifndef CENTROID_H
#define CENTROID_H

#include "DataPoint.h"
#include "Point.h"

struct Centroid : DataPoint
{
        int id;
        int nPoints;

        Centroid();
        Centroid(const double x, const double y);

        double distance(const DataPoint& p) const;

        ~Centroid() = default;
};

#endif // CENTROID_H