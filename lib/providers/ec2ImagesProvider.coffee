path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

ec2ImagesProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			ec2 = new @AWS.EC2({region: @region})
			Q.nbind(ec2.describeImages, ec2)({ Owners: [ 'self' ] })
				.then (data) =>
					_.map data.Images, (image) =>
						resource.generateResource image, image.ImageId, @region, tag.createTags(image.Tags), this
		catch e
			Q.reject e

ec2ImagesProvider.factory = (region) ->
	new ec2ImagesProvider region, aws, Q

module.exports = ec2ImagesProvider