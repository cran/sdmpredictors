# sdmpredictors 0.2.15
Remove dependency on defunct package rgdal.

# sdmpredictors 0.2.14
Add missing cloudmax layer

# sdmpredictors 0.2.13
Some layers had the wrong URL.

# sdmpredictors 0.2.12
Some Chlorophyll present layers had wrong URLs. These have been fixed.
A test was added to check the HTTP status of each layer URL.

# sdmpredictors 0.2.11

get_sysdata has been deprecated: sysdata.rda comes now uniquely from the package and is not downloaded from lifewatch.be

# sdmpredictors 0.2.10

Behrmann equal areas projection is now created on the fly from the original WGS84 layer
Bio-Oracle layers are downloaded from bio-oracle.org instead of lifewatch.be
sdmpredictors downloads layers now from specific URLs instead of relying on lifewatch.be/sdmpredictors and the layer_code

# sdmpredictors 0.2.9

Add bio-oracle v2.1

# sdmpredictors 0.2.8

Decrease test duration

# sdmpredictors 0.2.7

Add freshwater data

# sdmpredictors 0.2.6

Introduce dataset versions, fix citations

# sdmpredictors 0.2.5

Fix authors

# sdmpredictors 0.2.4

New datasets (ENVIREM, WorldClim paleo and future)
Added functions related to correlations

# sdmpredictors 0.2.3

Remove usage of ~/R/sdmpredictors from tests

# sdmpredictors 0.2.2

Fix url in description

# sdmpredictors 0.2.1

Fix urls in description and readme

# sdmpredictors 0.2

Datadir is mandatory now, instead of automatically writing to ~/R/sdmpredictors.

# sdmpredictors 0.1

Initial release of the sdmpredictors package.