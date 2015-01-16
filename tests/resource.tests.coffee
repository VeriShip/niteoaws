sinon = require 'sinon'
should = require 'should'
path = require 'path'
niteoaws = require(path.join __dirname, '../lib/niteoaws.js')

describe 'niteoaws', ->
	describe 'resource', ->
		describe 'generateResource', ->

			it 'The id field should be set.', ->

				obj = { }

				niteoaws.resource.generateResource obj, "testId"

				obj.id.should.be.equal "testId"

			it 'The region field should be set.', ->

				obj = { }

				niteoaws.resource.generateResource obj, "testId", "testRegion"

				obj.region.should.be.equal "testRegion"

			it 'The tags field should be set.', ->

				obj = { }

				niteoaws.resource.generateResource obj, "testId", "testRegion", "testtags"

				obj.tags.should.be.equal "testtags"

			it 'The provider field should be set.', ->

				obj = { }

				niteoaws.resource.generateResource obj, "testId", "testRegion", "testTags", "testProvider"

				obj.provider.should.be.equal "testProvider"