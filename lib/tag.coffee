tag = class
	constructor: (@key, @value)->

	equals: (tag) ->
		keyResult = false
		valueResult = false

		if !@key? or @key == ""
			keyResult = true
		else if typeof(@key) == 'function'
			keyResult = @key(tag.key)
		else
			keyResult = @key == tag.key

		if !@value? or @value == ""
			valueResult = true
		else if typeof(@value) == 'function'
			valueResult = @value(tag.value)
		else
			valueResult = @value == tag.value

		keyResult and valueResult

tag.createTags = (rawTagsArray) ->
	for singleTag in rawTagsArray
		new tag singleTag.Key, singleTag.Value
		

module.exports = tag
