sinon = require 'sinon'
assert = require 'should'
path = require 'path'
_ = require 'lodash'
niteoaws = require(path.join __dirname, '../../lib/niteoaws.js')

AWS = Q = fs = t = null
region = "Test Region"
	
getTarget = ->
	new niteoaws.iamSSLCertificateProvider(region, AWS)

localSetup = ->
	AWS = require 'aws-sdk'

describe 'niteoaws', ->

	beforeEach localSetup

	describe 'iamSSLCertificateProvider', ->

		describe 'getResources', ->

			generateTestCertificates = (pages, num) ->
				i = 0
				result = []

				while i < pages
					result.push { ServerCertificateMetadataList: [] , Marker: "Token: #{i}" }
					j = 0
					while j < num 
						j++
						result[i].ServerCertificateMetadataList.push { ServerCertificateId: "#{i}-#{j}", Tags: [] }

					i++

				result[0].Marker = null
				result


			it 'should return 50 resources when there are 5 pages with 10 items per page.', (done) ->

				numTimesProgressCalled = 0

				resources = generateTestCertificates 5, 10

				AWS =
					IAM: class
						listServerCertificates: (options, callback) ->
							callback null, resources.pop()

				certProvider = getTarget()

				certProvider.getResources()
					.done (data) ->
						data.length.should.be.equal(50)
						done()
					, (err) ->
				assert.fail 'An error should not have been thrown.'
				done()
			
			