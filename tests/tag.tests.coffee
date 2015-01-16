sinon = require 'sinon'
should = require 'should'
path = require 'path'
niteoaws = require(path.join __dirname, '../lib/niteoaws.js')

describe 'niteoaws', ->
	describe 'tag', ->
		describe 'equal', ->

			it 'should be equal if a.key == b.key and a.value == b.value', ->
				a = new niteoaws.tag "key", "value"
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should not be equal if a.key != b.key and a.value == b.value', ->
				a = new niteoaws.tag "key", "value"
				b = new niteoaws.tag "key1", "value"

				a.equals(b).should.be.false

			it 'should not be equal if a.key == b.key and a.value != b.value', ->
				a = new niteoaws.tag "key", "value"
				b = new niteoaws.tag "key", "value1"

				a.equals(b).should.be.false

			it 'should not be equal if a.key != b.key and a.value != b.value', ->
				a = new niteoaws.tag "key", "value"
				b = new niteoaws.tag "key1", "value1"

				a.equals(b).should.be.false

			it 'should be equal if a.key(b.key) == true and a.value == b.value', ->
				a = new niteoaws.tag ->
						true
					, "value"
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should not be equal if a.key(b.key) != true and a.value == b.value', ->
				a = new niteoaws.tag ->
						false
					, "value"
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.false

			it 'should not be equal if a.key(b.key) == true and a.value != b.value', ->
				a = new niteoaws.tag ->
						true	
					, "value"
				b = new niteoaws.tag "key", "value1"

				a.equals(b).should.be.false

			it 'should not be equal if a.key(b.key) != true and a.value != b.value', ->
				a = new niteoaws.tag ->
						false	
					, "value"
				b = new niteoaws.tag "key", "value1"

				a.equals(b).should.be.false

			it 'should be equal if a.key == b.key and a.value(b.value) == true', ->
				a = new niteoaws.tag "key", ->
					true
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should not be equal if a.key != b.key and a.value(b.value) == true', ->
				a = new niteoaws.tag "key", ->
					true
				b = new niteoaws.tag "key1", "value"

				a.equals(b).should.be.false

			it 'should not be equal if a.key == b.key and a.value(b.value) != true', ->
				a = new niteoaws.tag "key", ->
					false
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.false

			it 'should not be equal if a.key != b.key and a.value(b.value) != true', ->
				a = new niteoaws.tag "key", ->
					false
				b = new niteoaws.tag "key1", "value"

				a.equals(b).should.be.false

			it 'should be equal if a.key == "" and a.value == b.value', ->
				a = new niteoaws.tag "", "value"
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should be equal if a.key == null and a.value == b.value', ->
				a = new niteoaws.tag null, "value"
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should be equal if a.key == undefined and a.value == b.value', ->
				a = new niteoaws.tag undefined, "value"
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should not be equal if a.key == "" and a.value != b.value', ->
				a = new niteoaws.tag "", "value"
				b = new niteoaws.tag "key", "value1"

				a.equals(b).should.be.false

			it 'should not be equal if a.key == null and a.value != b.value', ->
				a = new niteoaws.tag null, "value"
				b = new niteoaws.tag "key", "value1"

				a.equals(b).should.be.false

			it 'should not be equal if a.key == undefined and a.value != b.value', ->
				a = new niteoaws.tag undefined, "value"
				b = new niteoaws.tag "key", "value1"

				a.equals(b).should.be.false

			it 'should be equal if a.key == b.key and a.value == ""', ->
				a = new niteoaws.tag "key", ""
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should be equal if a.key == b.key and a.value == null', ->
				a = new niteoaws.tag "key", null
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should be equal if a.key == b.key and a.value == undefined', ->
				a = new niteoaws.tag "key", undefined
				b = new niteoaws.tag "key", "value"

				a.equals(b).should.be.true

			it 'should not be equal if a.key != b.key and a.value == ""', ->
				a = new niteoaws.tag "key", ""
				b = new niteoaws.tag "key1", "value"

				a.equals(b).should.be.false

			it 'should not be equal if a.key != b.key and a.value == null', ->
				a = new niteoaws.tag "key", null
				b = new niteoaws.tag "key1", "value"

				a.equals(b).should.be.false

			it 'should not be equal if a.key != b.key and a.value == undefined', ->
				a = new niteoaws.tag "key", undefined
				b = new niteoaws.tag "key1", "value"

				a.equals(b).should.be.false

		describe 'createTags', ->

			it 'should return an array with 1 tag which has the equals method defined.', ->

				result = niteoaws.tag.createTags [
					{
						Key: "key",
						Value: "value"
					}
				]

				result.length.should.be.equal 1
				exists = result[0].equals?
				exists.should.be.true

			it 'should return an array with 2 tag which has the equals method defined.', ->

				result = niteoaws.tag.createTags [
					{
						Key: "key",
						Value: "value"
					},
					{
						Key: "key",
						Value: "value"
					}
				]

				result.length.should.be.equal 2
				for item in result
					exists = item.equals?
					exists.should.be.true
				