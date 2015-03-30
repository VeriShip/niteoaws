path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2ElasticIpsProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			ec2 = new @AWS.EC2({region: @region})
			Q.nbind(ec2.describeAddresses, ec2)({ })
				.then (data) =>
					_.map data.Addresses, (address) =>
						resource.generateResource address, address.Address, @region, [ ], this
		catch e
			Q.reject e

ec2ElasticIpsProvider.factory = (region) ->
	new ec2ElasticIpsProvider region, aws, Q

module.exports = ec2ElasticIpsProvider