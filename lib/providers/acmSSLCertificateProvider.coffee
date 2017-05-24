path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

acmSSLCertificateProvider = class extends resourceProvider
	constructor: (region, @AWS) ->
		super region


	getResources: (nextToken, resources, deferred) ->
		if !resources?
			resources = []

		if !deferred?
			deferred = Q.defer()

		try
			listCertificatesOptions = {}
			if nextToken?
				listCertificatesOptions.NextToken = nextToken

			acm = new @AWS.ACM({region: @region})
			acm.listCertificates listCertificatesOptions, (err, data) =>
				if err?
					deferred.reject err
				else
					for cert in data.CertificateSummaryList 
						resources.push(resource.generateResource cert, cert.CertificateArn, @region, [], this)
					if data.NextToken
						deferred.notify data.NextToken
						@getResources data.NextToken, resources, deferred
					else deferred.resolve resources
		catch e
			deferred.reject e

		return deferred.promise
		
acmSSLCertificateProvider.factory = (region) ->
	new acmSSLCertificateProvider region, aws

module.exports = acmSSLCertificateProvider