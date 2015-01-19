niteoaws
========
[![Build Status](https://travis-ci.org/NiteoSoftware/niteoaws.svg?branch=master)](https://travis-ci.org/NiteoSoftware/niteoaws)
[![Build status](https://ci.appveyor.com/api/projects/status/h1dmwhsf11ymnven?svg=true)](https://ci.appveyor.com/project/NiteoBuildBot/niteoaws)

*This is a work in progress and will be updated as need arises by the niteo software team.*

This library is meant to help dev ops represent our [AWS](http://aws.amazon.com/) infrastructure in JSON.  This way it is easily searchable.

Usage
-----

Prints out all instances within the `us-east-1` region.

```
niteoaws = require('niteoaws');

var ec2InstancesProvider = niteoaws.ec2InstanceProvider.factory('us-east-1');

ec2InstanceProvider.getResources().done(function(data) {
	console.log JSON.stringify(data, null, 4);	
})
```

Prints out all resources within the `us-east-1` region.

```
niteoaws = require('niteoaws');

niteoaws.getResources().done(function(data) {
	console.log JSON.stringify(data, null, 4);	
})
```

Currently Defined Providers:
---------------------------

-	cloudFormationProvider
-	ec2ElasticIpsProvider
-	ec2ImagesProvider
-	ec2InstanceProvider
-	ec2KeyPairsProvider
-	ec2PlacementGroupsProvider
-	ec2SecurityGroupsProvider
-	ec2SnapshotsProvider
-	ec2VolumesProvider
-	ec2VpcsProvider