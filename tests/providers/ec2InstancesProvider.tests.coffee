sinon = require 'sinon'
assert = require 'should'
path = require 'path'
_ = require 'lodash'
niteoaws = require(path.join __dirname, '../../lib/niteoaws.js')

AWS = Q = fs = t = null
region = "Test Region"
	
getTarget = ->
	new niteoaws.ec2InstancesProvider(region, AWS)

localSetup = ->
	AWS = require 'aws-sdk'

describe 'niteoaws', ->

	beforeEach localSetup

	describe 'ec2InstancesProvider', ->

		describe 'getResources', ->

			generateTestInstances = (pages, num) ->
				i = 0
				result = []

				while i < pages
					result.push { Reservations: [{ Instances: [] }], NextToken: "Token: #{i}" }
					j = 0
					while j < num
						j++
						result[i].Reservations[0].Instances.push { InstanceId: "#{i}-#{j}", Tags: [{ Key: "Key: #{j}", Value: "Value: #{j}" }] }
					i++

				result[0].NextToken = null
				result


			it 'should return 50 resources when there are 5 pages with 10 items per page.', (done) ->

				numTimesProgressCalled = 0

				resources = generateTestInstances 5, 10

				AWS = 
					EC2: class
						describeInstances: (options, callback) ->
							callback null, resources.pop()

				instanceProvider = getTarget()

				instanceProvider.getResources()
					.done (data) ->
							data.length.should.be.equal(50)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()


			it 'should return 100 resources when there are 2 pages with 50 items per page.', (done) ->

				numTimesProgressCalled = 0

				resources = generateTestInstances 2, 50

				AWS = 
					EC2: class
						describeInstances: (options, callback) ->
							callback null, resources.pop()

				instanceProvider = getTarget()

				instanceProvider.getResources()
					.done (data) ->
							data.length.should.be.equal(100)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()