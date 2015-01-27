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

		describe 'createKeyPair', (done) ->
				
				AWS = 
					EC2: class
						createKeyPair: (options, callback) ->
							callback "error", null

			it 'should throw an error if keyName is undefined.', (done) ->

				getTarget().createKeyPair(undefined).catch () ->
					done()

			it 'should throw an error if keyName is null.', (done) ->

				getTarget().createKeyPair(null).catch () ->
					done()

			it 'should pass the correct keyname in the options of the call.', (done) ->
				
				AWS = 
					EC2: class
						createKeyPair: (options, callback) ->
							callback null, options

				getTarget().createKeyPair("Some Key Name")
					.done (options) ->
							options.should.eql { KeyName: "Some Key Name" }
							done()

		describe 'deleteKeyPair', (done) ->
				
				AWS = 
					EC2: class
						deleteKeyPair: (options, callback) ->
							callback "error", null

			it 'should throw an error if keyName is undefined.', (done) ->

				getTarget().deleteKeyPair(undefined).catch () ->
					done()

			it 'should throw an error if keyName is null.', (done) ->

				getTarget().deleteKeyPair(null).catch () ->
					done()

			it 'should pass the correct keyname in the options of the call.', (done) ->
				
				AWS = 
					EC2: class
						deleteKeyPair: (options, callback) ->
							callback null, options

				getTarget().deleteKeyPair("Some Key Name")
					.done (options) ->
							options.should.eql { KeyName: "Some Key Name" }
							done()
