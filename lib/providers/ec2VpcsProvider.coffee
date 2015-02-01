path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2VpcsProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			ec2 = new @AWS.EC2({region: @region})
			Q.nbind(ec2.describeVpcs, ec2)({ })
				.then (data) =>
					_.map data.Vpcs, (vpc) ->
						resource.generateResource vpc, vpc.VpcId, @region, tag.createTags(vpc.Tags), this
		catch e
			Q.reject e

ec2VpcsProvider.factory = (region) ->
	new ec2VpcsProvider region, aws

module.exports = ec2VpcsProvider