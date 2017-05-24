sinon = require 'sinon'
assert = require 'should'
path = require 'path'
_ = require 'lodash'
niteoaws = require(path.join __dirname, '../../lib/niteoaws.js')

AWS = Q = fs = t = null

region = "Test Region"
	
getTarget = ->
	new niteoaws.acmSSLCertificateProvider(region, AWS)

localSetup = ->
	AWS = require 'aws-sdk'

describe 'niteoaws', ->

	beforeEach localSetup

	describe 'acmSSLCertificateProvider', ->

		describe 'getResources', ->

			generateTestCertificates = (pages, num) ->

				i = 0
				result = []
				
				while i < pages 
					result.push { CertificateSummaryList: [], NextToken: "NextToken: #{i}" }
					j = 0
					while j < num
						result[i].CertificateSummaryList.push {CertificateArn: "#{i}-#{j}", Tags: []}
						j++
					i++
				
				result[0].NextToken = null
				result

			it 'should return 50 resources when there are 5 pages with 10 items per page.', (done) ->

				numTimesProgressCalled = 0

				resources = generateTestCertificates 5, 10

				AWS =
					ACM: class
						listCertificates: (options, callback) ->
							callback null, resources.pop()

				certificateProvider = getTarget()

				certificateProvider.getResources()
					.done (data) ->
							data.length.should.be.equal(50)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()

			it 'should return 100 resources when there are 2 pages with 50 items per page.', (done) ->

				numTimesProgressCalled = 0

				resources = generateTestCertificates 2, 50

				AWS = 
					ACM: class
						listCertificates: (options, callback) ->
							callback null, resources.pop()

				certificateProvider = getTarget()

				certificateProvider.getResources()
					.done (data) ->
							data.length.should.be.equal(100)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()

			
			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					ACM: class
						constructor: ->
							throw 'Some Random Error'

				certificateProvider = getTarget()

				certificateProvider.getResources()
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()