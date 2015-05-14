path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2SubnetsProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			ec2 = new @AWS.EC2({region: @region})
			Q.nbind(ec2.describeSubnets, ec2)({ })
				.then (data) =>
					_.map data.Subnets, (subnet) =>
						resource.generateResource subnet, subnet.SubnetId, @region, tag.createTags(subnet.Tags), this
		catch e
			Q.reject e

ec2SubnetsProvider.factory = (region) ->
	new ec2SubnetsProvider region, aws

module.exports = ec2SubnetsProvider