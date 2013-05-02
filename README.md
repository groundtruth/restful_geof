# RestfulGeof - RESTful Geographic Features API

Talk to PostGIS in GeoJSON over HTTP.

## Setup



## Querying



## Planned functionality

* Accept database authentication credentials from HTTP headers.
* Read an individual feature by ID (e.g. `GET /api/database/table/22`).
* Find features closest to a point, or within a bounding box.
* Create new features.
* Update existing features.
* Delete existing features.
* Return results in a JSONP wrapper.
* CORS support.

## Limitations

* Assumes zero or one geometry column per table
* Assumes geometry column, not geography
* At least one non-geometry column
* 'is' condition values will be treated as integers if possible,
  otherwise strings (can force string with digits only by URI encoding).

