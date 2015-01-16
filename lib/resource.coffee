resource = class
	constructor: (@id, @region, @tags, @provider) ->

resource.generateResource = (sourceObject, id, region, tags, provider) ->
	sourceObject.id = id
	sourceObject.region = region
	sourceObject.tags = tags
	sourceObject.provider = provider
	return sourceObject

module.exports = resource