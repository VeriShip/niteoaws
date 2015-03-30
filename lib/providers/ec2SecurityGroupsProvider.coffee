path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2SecurityGroupsProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			ec2 = new @AWS.EC2({region: @region})
			Q.nbind(ec2.describeSecurityGroups, ec2)({ })
				.then (data) =>
					_.map data.SecurityGroups, (group) =>
						resource.generateResource group, group.GroupId, @region, tag.createTags(group.Tags), this
		catch e
			Q.reject e

ec2SecurityGroupsProvider.factory = (region) ->
	new ec2SecurityGroupsProvider region, aws, Q

module.exports = ec2SecurityGroupsProvider