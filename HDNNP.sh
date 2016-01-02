#!/bin/bash

## HDNNP execution script ##

## All input data have to be inside "data" directory ##

# Learn 673K and 973K temperatures and predict 773K temperature (base execution)
./HDNNP l673 l973 p773

# Learn 673K, 973K and 723K temperatures and predict 773K temperature (uncomment it to use)
#./HDNNP l673 l973 l723 p773

# Learn 673K, 973K and 773K temperatures and predict 723K temperature (uncomment it to use)
#./HDNNP l673 l973 l773 p723

# Learn 673K, 973K, 723K, 873K and 823K temperatures and predict 773K temperature (uncomment it to use)
#./HDNNP l673 l973 l723 l873 l823 p773

