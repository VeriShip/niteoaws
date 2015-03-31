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


	getResources: (marker, isTruncated, resources, deferred) ->
		if !resources?
			resources = []

		if !deferred?
			deferred = Q.defer()

		try
			listServerCertificatesOptions = {}
			if marker?
				listServerCertificatesOptions.Marker = marker
			if isTruncated?
				listServerCertificatesOptions.IsTruncated = isTruncated

			iam = new @AWS.IAM({region: @region})
			iam.listServerCertificates listServerCertificatesOptions, (err, data) =>
				if err?
					deferred.reject err
				else
					for cert in data.ServerCertificateMetadataList
						resources.push(resource.generateResource cert, cert.ServerCertificateId, @region, [], this)
					if data.IsTruncated
						deferred.notify data.Marker
						@getResources data.Marker, data.IsTruncated, resources, deferred
					else deferred.resolve resources
		catch e
			deferred.reject e

		return deferred.promise
		
iamSSLCertificateProvider.factory = (region) ->
	new iamSSLCertificateProvider region, aws

module.exports = iamSSLCertificateProvider