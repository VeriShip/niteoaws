sinon = require 'sinon'
assert = require 'should'
path = require 'path'
_ = require 'lodash'
Q = require 'q'
niteoaws = require(path.join __dirname, '../lib/niteoaws.js')

region = "Test Region"

describe 'niteoaws', ->

	describe 'resourceProvider', ->

		describe 'constructor', ->

			it 'should raise an exception if region is null.', ->

				(() -> new niteoaws.resourceProvider(null)).should.throw()

			it 'should raise an exception if region is undefined.', ->

				(() -> new niteoaws.resourceProvider(undefined)).should.throw()

		describe 'findResources', ->

			resources = 
				[
					{ tags: [] },
					{ 
						tags: [
							{ key: "key 1", value: "value 1"}
						]
					},
					{ 
						tags: [
							{ key: "key 1", value: "value 1"}
							{ key: "key 2", value: "value 2"}
							{ key: "key 3", value: "value 3"}
						]
					}
				]

			targetClass = class extends niteoaws.resourceProvider
				getResources: () ->
					Q(resources)

			target = new targetClass region

			it 'should return all resources if query is empty.', (done) ->

				target.findResources([ ])
					.done (data) ->
							data.length.should.equal resources.length
							done()

			it 'should return all resources if query is null.', (done) ->

				target.findResources(null)
					.done (data) ->
							data.length.should.equal resources.length
							done()

			it 'should return all resources if query is undefined.', (done) ->

				target.findResources(undefined)
					.done (data) ->
							data.length.should.equal resources.length
							done()

			it 'should return resources with matching tags. (Single key tag)', (done) ->

				query = [
					new niteoaws.tag "key 1"
				]

				target.findResources(query)
					.done (data) ->
							data.length.should.be.greaterThan 0
							itemCheck = _.all data, (resource)->
								_.any resource.tags, (tag)->
									query[0].equals tag

							itemCheck.should.be.true
							done()

			it 'should return resources with matching tags. (Single key and value tag)', (done) ->

				query = [
					new niteoaws.tag "key 1", "value 1"
				]

				target.findResources(query)
					.done (data) ->
							data.length.should.be.greaterThan 0
							itemCheck = _.all data, (resource)->
								_.any resource.tags, (tag)->
									query[0].equals tag

							itemCheck.should.be.true
							done()

			it 'should return resource with matching tags. (Multiple key tag)', (done) ->

				query = [
					new niteoaws.tag "key 1"
					new niteoaws.tag "key 2"
				]

				target.findResources(query)
					.done (data) ->
							data.length.should.be.greaterThan 0
							itemCheck = _.all data, (resource)->
								_.any resource.tags, (tag)->
									query[0].equals tag

							itemCheck.should.be.true
							done()

			it 'should return resource with matching tags. (Multiple key and value tag)', (done) ->

				query = [
					new niteoaws.tag "key 1", "value 1"
					new niteoaws.tag "key 2"
				]

				target.findResources(query)
					.done (data) ->
							data.length.should.be.greaterThan 0
							itemCheck = _.all data, (resource)->
								_.any resource.tags, (tag)->
									query[0].equals tag

							itemCheck.should.be.true
							done()

			it 'should return resource with matching tags. (Multiple key and value tag)', (done) ->

				query = [
					new niteoaws.tag "key 1", "value 1"
					new niteoaws.tag "key 2"
				]

				target.findResources(query)
					.done (data) ->
							data.length.should.be.greaterThan 0
							itemCheck = _.all data, (resource)->
								_.any resource.tags, (tag)->
									query[0].equals tag

							itemCheck.should.be.true
							done()

			it 'should return resource with matching tags. (Single key as function tag)', (done) ->

				query = [
					new niteoaws.tag (key) ->
						key == "key 1"
				]

				target.findResources(query)
					.done (data) ->
							data.length.should.be.greaterThan 0
							itemCheck = _.all data, (resource)->
								_.any resource.tags, (tag)->
									query[0].equals tag

							itemCheck.should.be.true
							done()

			it 'should not return resources with matching tags.', (done) ->

				query = [
					new niteoaws.tag null, "value 6"
				]

				target.findResources(query)
					.done (data) ->
							data.length.should.equal 0
							done()

		describe 'getResource', ->

			#	Set the timeout to a low value.
			this.timeout 10

			resources = 
				[
					{ id: "Some Id" },
					{ id: "Some Id 1" },
					{ id: "Some Id 2" },
					{ id: "Some Id 3" }
				]

			targetClass = class extends niteoaws.resourceProvider
				getResources: () ->
					Q(resources)

			target = new targetClass region

			it 'should raise error if id is null', (done) ->

				target.getResource null
					.catch (err) ->
						done()

			it 'should raise error if id is undefined', (done) ->

				target.getResource undefined
					.catch (err) ->
						done()

			it 'should return correct resource.', (done) ->

				target.getResource "Some Id 1"
					.done (data) ->
						data.id.should.equal resources[1].id
						done()

			it 'should return null if resource is not found.', (done) ->

				target.getResource "Some Id Unknown"
					.done (data) ->
						(data?).should.be.false
						done()
