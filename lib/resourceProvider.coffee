_ = require 'lodash'
Q = require 'q'

resourceProvider = class
	constructor: (@region) ->
		if !@region?
			throw 'You must supply a region.'

	getResources: () ->
		throw 'This method needs to be overwritten.'

	getResource: (id) ->
		if !id? 
			return Q.reject 'You must supply an id.'

		@getResources()
			.then (data) ->
				_.find data, (resource) ->
					resource.id == id

	findResources: (queryTags) ->
		@getResources()
			.then (data) ->
				_.filter data, (resource) ->
					if !queryTags? or queryTags.length == 0
						return true;
					else
						_.any resource.tags, (tag) ->
							_.any queryTags, (queryTag) ->
								queryTag.equals tag

module.exports = resourceProvider