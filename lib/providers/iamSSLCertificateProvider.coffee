path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

iamSSLCertificateProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region

	getResources: () ->
		try
			iam = new @AWS.IAM({region: @region})
			Q.nbind(iam.listServerCertificates, iam)({ })
				.then (data) =>
					_.map data.ServerCertificateMetadataList, (cert) ->
						resource.generateResource cert, cert.ServerCertificateId, @region, [ ], this
		catch e
			Q.reject e

iamSSLCertificateProvider.factory = (region) ->
	new iamSSLCertificateProvider region, aws, Q

module.exports = iamSSLCertificateProvider