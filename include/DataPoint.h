#ifndef DATAPOINT_H
#define DATAPOINT_H

struct DataPoint
{
        double x;
        double y;
        
        DataPoint();
        DataPoint(const double _x, const double _y);

        // getters
        double getX() const;
        double getY() const;

        ~DataPoint() = default;
};

#endif // DATAPOINT_H