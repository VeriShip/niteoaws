path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2SnapshotsProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			ec2 = new @AWS.EC2({region: @region})
			Q.nbind(ec2.describeSnapshots, ec2)(
				OwnerIds: ["self"]
			)
				.then (data) =>
					_.map data.Snapshots, (snapshot) =>
						resource.generateResource snapshot, snapshot.SnapshotId, @region, tag.createTags(snapshot.Tags), this
		catch e
			Q.reject e

ec2SnapshotsProvider.factory = (region) ->
	new ec2SnapshotsProvider region, aws, Q

module.exports = ec2SnapshotsProvider