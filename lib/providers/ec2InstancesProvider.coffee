path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2InstancesProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region
	
	getResources: (nextToken, resources, deferred) ->

		if !resources?
			resources = []

		if !deferred?
			deferred = Q.defer()

		describeInstancesOptions = { }
		if nextToken?
			describeInstancesOptions.NextToken = nextToken

		ec2 = new @AWS.EC2({region: @region})
		ec2.describeInstances describeInstancesOptions, (err, data) =>
			if err?
				deferred.reject err
			else 
				for reservation in data.Reservations
					for instance in reservation.Instances
						resources.push(resource.generateResource instance, instance.InstanceId, @region, tag.createTags(instance.Tags), this)

				if data.NextToken?
					deferred.notify data.NextToken
					@getResources data.NextToken, resources, deferred
				else
					deferred.resolve resources

		return deferred.promise

ec2InstancesProvider.factory = (region) ->
	new ec2InstancesProvider region, aws

module.exports = ec2InstancesProvider