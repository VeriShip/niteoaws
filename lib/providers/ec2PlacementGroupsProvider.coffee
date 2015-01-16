path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2PlacementGroupsProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		ec2 = new @AWS.EC2({region: @region})
		Q.nbind(ec2.describePlacementGroups, ec2)({ })
			.then (data) =>
				_.map data.PlacementGroups, (group) ->
					resource.generateResource group, group.GroupName, @region, [ ], this

ec2PlacementGroupsProvider.factory = (region) ->
	new ec2PlacementGroupsProvider region, aws, Q

module.exports = ec2PlacementGroupsProvider