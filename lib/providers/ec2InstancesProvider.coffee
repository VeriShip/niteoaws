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

	getResources: () ->
		ec2 = new @AWS.EC2({region: @region})
		Q.nbind(ec2.describeInstances, ec2)()
			.then (data) =>
				_.map data.Reservations.Instances, (instance) ->
					resource.generateResource instance, instance.InstanceId, @region, tag.createTags(instance.Tags), this

ec2InstancesProvider.factory = (region) ->
	new ec2InstancesProvider region, aws, Q

module.exports = ec2InstancesProvider