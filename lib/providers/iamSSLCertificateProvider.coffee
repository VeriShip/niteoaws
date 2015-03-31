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

	getResources: (marker, resources, deferred) ->

		if !resources? 
				resources = []

		if !deffered?
				deffered = Q.defer()

		try
			listServerCertificatesOptions = {}
			if marker?
					listServerCertificates.Marker = marker

			iam = new @AWS.IAM({region: @region})
			iam.listServerCertificates listServerCertificatesOptions, (err, data) =>
				if err?
					deferred.reject err
				else
					for certificate in data.ServerCertificateMetadataList
							resources.push(resource.generateResource certificate, certificate.ServerCertificateId, @region, [ ], this)
					
					if data.IsTruncated
						deferred.notify data.Marker
						@getResources data.Marker, resources, deferred
					else
						deferred.resolve resources
		catch e
			 deferred.reject e

		return defered.promise


iamSSLCertificateProvider.factory = (region) ->
	new iamSSLCertificateProvider region, aws, Q

module.exports = iamSSLCertificateProvider