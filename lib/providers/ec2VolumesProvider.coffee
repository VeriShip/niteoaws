path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2VolumesProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			ec2 = new @AWS.EC2({region: @region})
			Q.nbind(ec2.describeVolumes, ec2)({ })
				.then (data) =>
					_.map data.Volumes, (volume) =>
						resource.generateResource volume, volume.VolumeId , @region, tag.createTags(volume.Tags), this
		catch e
			Q.reject e

ec2VolumesProvider.factory = (region) ->
	new ec2VolumesProvider region, aws, Q

module.exports = ec2VolumesProvider