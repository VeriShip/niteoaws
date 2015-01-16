sinon = require 'sinon'
should = require 'should'
path = require 'path'
_ = require 'lodash'
fs = require 'fs'
niteoaws = require(path.join __dirname, '../lib/niteoaws.js')

#	Notice this test is skipped.  This is a simple test I created to try out exporting our infrastructure to JSON.
describe.skip 'test', ->
	this.timeout 10000

	target = new niteoaws('us-west-2')

	it 'test', (done) ->

		target.getResources()
			.done (data) ->
					data = _.map data, (d) ->
						d.provider = null
						d

					fs.writeFileSync('./test.json', JSON.stringify(data, null, 4))
					done()
				, (err) ->
					console.log err
					(true).should.be.false
					done()
					