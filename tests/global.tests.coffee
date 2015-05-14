sinon = require 'sinon'
should = require 'should'
path = require 'path'
_ = require 'lodash'
fs = require 'fs'
niteoaws = require(path.join __dirname, '../lib/niteoaws.js')

#	Notice this test is skipped.  This is a simple test I created to try out exporting our infrastructure to JSON.
describe.skip 'test', ->
	this.timeout 10000

	target = new niteoaws.ec2SubnetsProvider('us-west-2', require 'aws-sdk')

	it 'test', (done) ->

		target.getResources()
			.done (data) ->
					console.dir data
					done()
				, (err) ->
					console.log err
					(true).should.be.false
					done()
					