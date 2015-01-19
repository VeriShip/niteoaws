sinon = require 'sinon'
assert = require 'should'
path = require 'path'
_ = require 'lodash'
niteoaws = require(path.join __dirname, '../../lib/niteoaws.js')

AWS = null
region = "Test Region"
	
getTarget = ->
	new niteoaws.ec2KeyPairsProvider(region, AWS)

localSetup = ->
	AWS = require 'aws-sdk'

describe 'niteoaws', ->

	beforeEach localSetup

	describe 'ec2KeyPairsProvider', ->

		describe 'getResources', ->

			generateTestKeyPairs = (num) ->
				i = 0
				result = { KeyPairs: [] }

				while i < num 
					result.KeyPairs.push { KeyName: i }
					i++
				result

			getResourcesTests = (num, done) ->

				resources = generateTestKeyPairs num

				AWS = 
					EC2: class
						describeKeyPairs: (options, callback) ->
							callback null, resources

				niteoKeyPairs = getTarget()

				niteoKeyPairs.getResources()
					.done (data) ->
							data.length.should.be.equal(num)
							i = 0
							while i < num
								resources.KeyPairs[i].KeyName.should.equal(data[i].id)
								i++
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()

			it 'should return 1 resources when there are 1 items.', (done) ->

				getResourcesTests 1, done

			it 'should return 10 resources when there are 10 items.', (done) ->

				getResourcesTests 10, done

			it 'should return 100 resources when there are 100 items.', (done) ->

				getResourcesTests 100, done