path = require 'path'
_ = require 'lodash'
Q = require 'q'
aws = require 'aws-sdk'
fs = require 'fs'
tag = require path.join(__dirname, '../tag.js')
resource = require path.join(__dirname, '../resource.js')
resourceProvider = require path.join(__dirname, '../resourceProvider.js')

timeAbstraction = class
	setTimeout: (callback, delay) ->
		setTimeout(callback, delay)

cloudFormationProvider = class extends resourceProvider
	constructor: (region, @AWS, @Q, @fs, @t) ->
		super region

	getResources: (nextToken, resources, deferred) ->

		if !resources?
			resources = []

		if !deferred?
			deferred = @Q.defer()

		try
			describeStacksOptions = { }
			if nextToken?
				describeStacksOptions.NextToken = nextToken

			cf = new @AWS.CloudFormation({region: @region})
			cf.describeStacks describeStacksOptions, (err, data) =>
				if err?
					deferred.reject err
				else 
					for stack in data.Stacks
						resources.push(resource.generateResource stack, stack.StackId, @region, tag.createTags(stack.Tags), this)

					if data.NextToken?
						deferred.notify data.NextToken
						@getResources data.NextToken, resources, deferred
					else
						deferred.resolve resources
		catch e
			deferred.reject e

		return deferred.promise

	validateTemplate: (templateBody) ->

		if !templateBody?
			return @Q.reject 'You must define the templateBody.'

		try
			cf = new @AWS.CloudFormation({region: @region})
			@Q.nbind(cf.validateTemplate, cf)({ TemplateBody: templateBody })
		catch e
			@Q.reject e

	doesStackExist: (stackName) ->

		if !stackName?
			return @Q.reject 'You must define stackName.'

		deferred = @Q.defer()

		try
			cf = new @AWS.CloudFormation({ region: @region })
			cf.describeStacks { }, (err, data) ->

				if err?
					deferred.reject err
				else
					foundStacks = _.find data.Stacks, 
						StackName: stackName

					deferred.resolve foundStacks?
		catch e
			deferred.reject e

		deferred.promise

	getStackId: (stackName) ->

		if !stackName?
			return @Q.reject 'You must define stackName.'

		deferred = @Q.defer()

		try
			cf = new @AWS.CloudFormation({ region: @region })
			cf.describeStacks { StackName: stackName }, (err, data) ->

				if err?
					deferred.reject err
				else
					foundStacks = _.find data.Stacks, 
						StackName: stackName

					if foundStacks?
						deferred.resolve foundStacks.StackId
					else
						deferred.reject "Unable to find the stack #{stackName} amongst the active stacks."
		catch e
			deferred.reject e

		deferred.promise

	pollStackStatus: (stackId, successStatuses, failureStatuses, deferred) ->

		if !stackId?
			deferred.reject 'You must supply a stackId.'
			return

		if !successStatuses?
			deferred.reject 'You must supply a successStatuses.'
			return

		if successStatuses.length == 0
			deferred.reject 'You must supply an array of successStatuses.'
			return

		if !failureStatuses?
			deferred.reject 'You must supply a failureStatuses.'
			return

		if failureStatuses.length == 0
			deferred.reject 'You must supply an array of failureStatuses.'
			return

		try
			cf = new @AWS.CloudFormation({ region: @region })
			cf.describeStacks { StackName: stackId }, (err, data) =>
				if err?
					deferred.reject err	
				else
					targetStack = _.find data.Stacks, { StackId: stackId }
					
					if !targetStack?
						deferred.reject "Unable to find the stack #{stackId}"
					else if _.contains failureStatuses, targetStack.StackStatus
						deferred.reject "The stack reached a failed status: #{targetStack.StackStatus}"
					else if _.contains successStatuses, targetStack.StackStatus
						deferred.resolve targetStack.StackStatus
					else
						deferred.notify targetStack.StackStatus
						@t.setTimeout( =>
								@pollStackStatus stackId, successStatuses, failureStatuses, deferred 
							5000)
		catch e
			deferred.reject e

	createStack: (stackName, templateBody, parameters) ->

		if !stackName?
			return @Q.reject 'You must define stackName'

		if !templateBody?
			return @Q.reject 'You must define templateBody'

		deferred = @Q.defer()

		try
			createStackOptions = 
				StackName: stackName,
				TemplateBody: templateBody

			if parameters?
				createStackOptions.Parameters = parameters

			cf = new @AWS.CloudFormation({ region: @region })
			cf.createStack createStackOptions, (err, data) =>
				if err?
					deferred.reject err
				else
					@getStackId(stackName)
						.done (id) =>
								@pollStackStatus id, ["CREATE_COMPLETE"], ["CREATE_FAILED", "ROLLBACK_COMPLETE", "ROLLBACK_FAILED"], deferred
							, (err) =>
								deferred.reject err
		catch e
			deferred.reject e

		deferred.promise

	deleteStack: (stackName) ->
		if !stackName?
			return @Q.reject 'You must define stackName'

		deferred = @Q.defer()

		try
			cf = new @AWS.CloudFormation({ region: @region })
			cf.deleteStack { StackName: stackName }, (err, data) =>
				if err?
					deferred.reject err
				else
					@getStackId(stackName)
						.done (id) =>
								@pollStackStatus id, ["DELETE_COMPLETE", "DELETE_SKIPPED"], ["DELETE_FAILED"], deferred
							, (err) =>
								deferred.reject err
		catch e
			deferred.reject e

		deferred.promise

	updateStack: (stackName, templateBody, parameters) ->

		if !stackName?
			return @Q.reject 'You must define stackName'

		if !templateBody?
			return @Q.reject 'You must define templateBody'

		deferred = @Q.defer()

		try
			updateStackOptions = 
				StackName: stackName,
				TemplateBody: templateBody

			if parameters?
				updateStackOptions.Parameters = parameters

			cf = new @AWS.CloudFormation({ region: @region })
			cf.updateStack updateStackOptions, (err, data) =>
				if err?
					deferred.reject err
				else
					@getStackId(stackName)
						.done (id) =>
								@pollStackStatus id, ["UPDATE_COMPLETE"], ["UPDATE_ROLLBACK_FAILED", "UPDATE_ROLLBACK_COMPLETE"], deferred
							, (err) =>
								deferred.reject err
		catch e
			deferred.reject e
		
		deferred.promise

cloudFormationProvider.factory = (region) ->
	new cloudFormationProvider region, aws, Q, fs, new timeAbstraction()

module.exports = cloudFormationProvider