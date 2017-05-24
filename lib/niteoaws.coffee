path = require 'path'
Q = require 'q'
_ = require 'lodash'
tag = require(path.join(__dirname, 'tag.js'))
resource = require(path.join(__dirname, 'resource.js'))
resourceProvider = require(path.join(__dirname, 'resourceProvider.js'))
cloudFormationProvider = require(path.join(__dirname, 'providers/cloudFormationProvider.js')) 
ec2ImagesProvider = require(path.join(__dirname, 'providers/ec2ImagesProvider.js')) 
ec2InstancesProvider = require(path.join(__dirname, 'providers/ec2InstancesProvider.js')) 
ec2ElasticIpsProvider = require(path.join(__dirname, 'providers/ec2ElasticIpsProvider.js')) 
ec2KeyPairsProvider = require(path.join(__dirname, 'providers/ec2KeyPairsProvider.js')) 
ec2PlacementGroupsProvider = require(path.join(__dirname, 'providers/ec2PlacementGroupsProvider.js')) 
ec2SecurityGroupsProvider = require(path.join(__dirname, 'providers/ec2SecurityGroupsProvider.js')) 
ec2SnapshotsProvider = require(path.join(__dirname, 'providers/ec2SnapshotsProvider.js')) 
ec2VolumesProvider = require(path.join(__dirname, 'providers/ec2VolumesProvider.js')) 
ec2VpcsProvider = require(path.join(__dirname, 'providers/ec2VpcsProvider.js')) 
ec2SubnetsProvider = require(path.join(__dirname, 'providers/ec2SubnetsProvider.js')) 
iamSSLCertificateProvider = require(path.join(__dirname, 'providers/iamSSLCertificateProvider.js')) 
acmSSLCertificateProvider = require(path.join(__dirname, 'providers/acmSSLCertificateProvider.js')) 

niteoaws = class extends resourceProvider
	constructor: (region) ->
		super region

	getResources: () ->
		deferred = Q.defer()
		Q.all _.map(niteoaws.resourceProviders, (provider) => 
			provider.factory(@region).getResources()
		)
			.done (dataArray) ->
					deferred.resolve _.flatten dataArray
				, (err) ->
					deferred.reject err
		deferred.promise

niteoaws.tag = tag
niteoaws.resource = resource
niteoaws.resourceProvider = resourceProvider
niteoaws.resourceProviders = [
	cloudFormationProvider,
	ec2ImagesProvider,
	ec2InstancesProvider,
	ec2ElasticIpsProvider,
	ec2KeyPairsProvider,
	ec2PlacementGroupsProvider,
	ec2SecurityGroupsProvider,
	ec2SnapshotsProvider,
	ec2VolumesProvider,
	ec2VpcsProvider,
	ec2SubnetsProvider,
	iamSSLCertificateProvider,
	acmSSLCertificateProvider
]
niteoaws.cloudFormationProvider = cloudFormationProvider
niteoaws.ec2ImagesProvider = ec2ImagesProvider
niteoaws.ec2InstancesProvider = ec2InstancesProvider
niteoaws.ec2ElasticIpsProvider = ec2ElasticIpsProvider
niteoaws.ec2KeyPairsProvider = ec2KeyPairsProvider
niteoaws.ec2PlacementGroupsProvider = ec2PlacementGroupsProvider 
niteoaws.ec2SecurityGroupsProvider = ec2SecurityGroupsProvider
niteoaws.ec2SnapshotsProvider = ec2SnapshotsProvider
niteoaws.ec2VolumesProvider = ec2VolumesProvider
niteoaws.ec2VpcsProvider = ec2VpcsProvider
niteoaws.ec2SubnetsProvider = ec2SubnetsProvider
niteoaws.iamSSLCertificateProvider = iamSSLCertificateProvider
niteoaws.acmSSLCertificateProvider = acmSSLCertificateProvider

module.exports = niteoaws
