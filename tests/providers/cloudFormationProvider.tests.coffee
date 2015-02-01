sinon = require 'sinon'
assert = require 'should'
path = require 'path'
niteoaws = require(path.join __dirname, '../../lib/niteoaws.js')

AWS = Q = fs = t = null
region = "Test Region"
	
getTarget = ->
	new niteoaws.cloudFormationProvider(region, AWS, Q, fs, t)

localSetup = ->
	AWS = require 'aws-sdk'
	Q = require 'q'
	fs = require 'fs'
	
	#	This is an abstraction for the setTimeout method.
	#	The delay in this object is ignored.
	t =
		setTimeout: (callback, delay) ->
			callback() 

describe 'niteoaws', ->

	beforeEach localSetup

	describe 'cloudFormationProvider', ->

		describe 'getResources', ->

			generateTestStacks = (pages, num) ->
				i = 0
				result = []

				while i < pages
					result.push { Stacks: [], NextToken: "Token: #{i}" }
					j = 0
					while j < num
						j++
						result[i].Stacks.push { StackId: "", Tags: [] }
					i++

				result[0].NextToken = null
				result


			it 'should return 50 resources when there are 5 pages with 10 items per page.', (done) ->

				numTimesProgressCalled = 0

				resources = generateTestStacks 5, 10

				AWS = 
					CloudFormation: class
						describeStacks: (options, callback) ->
							callback null, resources.pop()

				niteoCF = getTarget()

				niteoCF.getResources()
					.done (data) ->
							data.length.should.be.equal(50)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()


			it 'should return 100 resources when there are 2 pages with 50 items per page.', (done) ->

				numTimesProgressCalled = 0

				resources = generateTestStacks 2, 50

				AWS = 
					CloudFormation: class
						describeStacks: (options, callback) ->
							callback null, resources.pop()

				niteoCF = getTarget()

				niteoCF.getResources()
					.done (data) ->
							data.length.should.be.equal(100)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()

			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				getTarget().getResources()
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()

		describe 'validateTemplate', ->

			it 'should throw an exception if templateBody is null', (done) ->

				getTarget().validateTemplate null, "body"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should throw an exception if templateBody is undefined', (done) ->

				getTarget().validateTemplate niteoaws.undefinedMethod, "body"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should throw an exception if the template is not valid.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						validateTemplate: (body, callback) ->
							callback "Random Error", null
							
				niteoCF = getTarget()

				content = "{ }"
				niteoCF.validateTemplate(content, "us-west-2")
					.done	(data) ->
							assert.fail 'An error was expected.'
							done()
						, (err) ->
							done()

			it 'should show success if the template is valid.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						validateTemplate: (body, callback) ->
							callback null, "Success"
							
				niteoCF = getTarget()

				content = "{ }"
				niteoCF.validateTemplate(content, "us-west-2")
					.done	(data) ->
							done()
						, (err) ->
							assert.fail 'The template should be valid.'
							done()

			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				getTarget().validateTemplate( { }, "us-west-2")
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()

		describe 'doesStackExist', ->

			it 'should throw an exception if stackName is null', (done) ->
				getTarget().doesStackExist null, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined', (done) ->
				getTarget().doesStackExist undefined, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should return true if the stack exists.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [
									StackName: options.StackName
								]

				niteoCF = getTarget()

				niteoCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.true
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return true if the stack exists. (mutiple stacks returned.)', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [
									{ StackName: "Some Random Stack" },
									{ StackName: options.StackName },
									{ StackName: "Some Other Random Stack" },
								]

				niteoCF = getTarget()

				niteoCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.true
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()

			it 'should return false if the stack does not exist. (no stacks returned.)', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [ ]

				niteoCF = getTarget()

				niteoCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.false
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return false if the stack does not exist. (stacks returned but stack queried was not found.)', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [
									{ StackName: "Some Random Stack" }
								]

				niteoCF = getTarget()

				niteoCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.false
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return false if the stack does not exist. (Stacks is undefined)', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, { }

				niteoCF = getTarget()

				niteoCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.false
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return an error if an error occured.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback "Some Error", null

				niteoCF = getTarget()

				niteoCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						assert.fail 'An error should have been raised.'
						done()
					, (err) ->
						done()

			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				niteoCF = getTarget()
				niteoCF.doesStackExist("TestStackName", "TestRegion")
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()

		describe 'getStackId', ->

			it 'should throw an exception if stackName is null', (done) ->
				getTarget().getStackId null, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined', (done) ->
				getTarget().getStackId undefined, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should return stackId if the stack exists.', (done) ->
				
				expectedStackId = "Test Stack Id"

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [
									StackName: options.StackName
									StackId: expectedStackId
								]

				niteoCF = getTarget()

				niteoCF.getStackId("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.equal expectedStackId	
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()

			it 'should return error if the stack is not found.', (done) ->
				
				expectedStackId = "Test Stack Id"

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [ ]

				niteoCF = getTarget()

				niteoCF.getStackId("TestStackName", "TestRegion")
					.done (data) ->
						assert.fail 'An error should have been thrown here.'
						done()
					, (err) ->
						done()

			it 'should return error if an error occured.', (done) ->
				
				expectedStackId = "Test Stack Id"

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback "Some Error", null

				niteoCF = getTarget()

				niteoCF.getStackId("TestStackName", "TestRegion")
					.done (data) ->
						assert.fail 'An error should have been thrown here.'
						done()
					, (err) ->
						done()

			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				niteoCF = getTarget()
				niteoCF.getStackId("TestStackName", "TestRegion")
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()

		describe 'pollStackStatus', ->

			it 'should throw an exception if stackId is null.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus(null, [ "" ], [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if stackId is undefined.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus(undefined, [ "" ], [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if successStatuses is null.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus("stackId", null, [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if successStatuses is undefined.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus("stackId", undefined, [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if successStatuses is empty.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus("stackId", [ ], [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if failureStatuses is null.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus("stackId", [ "" ], null, deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if failureStatuses is undefined.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus("stackId", [ "" ], undefined, deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if failureStatuses is empty.', (done) ->
				deferred = Q.defer()
				getTarget().pollStackStatus("stackId", [ "" ], [ ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return an error if one is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback "Some Error", null	

				niteoCF = getTarget()
				deferred = Q.defer()

				niteoCF.pollStackStatus "stackId", [ "" ], [ "" ], deferred
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return an error if no stacks are found.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null,
								Stacks: [ ] 

				niteoCF = getTarget()
				deferred = Q.defer()

				niteoCF.pollStackStatus "stackId", [ "" ], [ "" ], deferred
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return an error if a stack is found with a failure status.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null,
								Stacks: [ 
									StackId: "stackId"
									StackStatus: "Some Failure Status"
								] 

				niteoCF = getTarget()
				deferred = Q.defer()

				niteoCF.pollStackStatus "stackId", [ "" ], [ "Some Failure Status" ], deferred
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return success if a stack is found with a success status.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null,
								Stacks: [ 
									StackId: "stackId"
									StackStatus: "Some Success Status"
								] 

				niteoCF = getTarget()
				deferred = Q.defer()

				niteoCF.pollStackStatus "stackId", [ "Some Success Status" ], [ "Some Failure" ], deferred
				deferred.promise
					.done (data) ->
						done()
					, (err) ->
						assert.fail 'There should not have been an exception thrown.'
						done()

			it 'should return an error if a stack is found with a failure status. (Multiple Iterations.)', (done) ->
				targetStackId = "Some Stack Id"
				failureStackStatus = "Failure Status"
				failureStatuses = [ "Some Other Failure", failureStackStatus ]
				stackQueue = [
					{
						Stacks: [
							StackId: targetStackId 
							StackStatus: failureStackStatus
						]
					},
					{
						Stacks: [
							StackId: targetStackId 
							StackStatus: "Some Pending Status"
						]
					}
				]

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				niteoCF = getTarget()
				deferred = Q.defer()

				niteoCF.pollStackStatus targetStackId, [ "" ], failureStatuses, deferred
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return success if a stack is found with a success status. (Multiple Iterations.)', (done) ->
				targetStackId = "Some Stack Id"
				successStackStatus = "Success Status"
				successStatuses = [ "Some Other Success", successStackStatus ]
				stackQueue = [
					{
						Stacks: [
							StackId: targetStackId 
							StackStatus: successStackStatus
						]
					},
					{
						Stacks: [
							StackId: targetStackId 
							StackStatus: "Some Pending Status"
						]
					}
				]

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				niteoCF = getTarget()
				deferred = Q.defer()

				niteoCF.pollStackStatus targetStackId, successStatuses, [ "" ], deferred
				deferred.promise
					.done (data) ->
						done()
					, (err) ->
						assert.fail 'There should not have been an exception thrown.'
						done()

			it 'should still return a promise if an exception is encountered.', (done) ->

				targetStackId = "Some Stack Id"
				successStackStatus = "Success Status"
				successStatuses = [ "Some Other Success", successStackStatus ]

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				deferred = Q.defer()
				niteoCF = getTarget()
				niteoCF.pollStackStatus targetStackId, successStatuses, [ "" ], deferred
				deferred.promise
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()

		describe 'createStack', ->

			it 'should throw an exception if stackName is null.', (done) ->
				getTarget().createStack null, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined.', (done) ->
				getTarget().createStack undefined, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is null.', (done) ->
				getTarget().createStack "stackName", null
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is undefined.', (done) ->
				getTarget().createStack "stackName", undefined
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should raise an exception if an exception happens.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						createStack: (options, callback) ->
							callback "someException", null

				niteoCF = getTarget() 

				niteoCF.createStack "stackName", "body", { Parameters: [ ] }
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			createStackTestPolling = (stackName, resultStackStatus, numPolls, isSuccess, done) ->
				stackQueue = [
					{
						Stacks: [
							StackName: stackName
							StackId: "Some Id"
							StackStatus: resultStackStatus
						]
					}
				]

				#	We loop through numPolls + 1 because the 'getStackId' takes an extra call to describeStacks.
				i = 0
				while i < numPolls + 1	
					i++
					stackQueue.push
						Stacks: [
							StackName: stackName
							StackId: "Some Id"
							StackStatus: "Some Pending Status"
						]

				numTimesProgressCalled = 0

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						createStack: (options, callback) ->
							callback null, "Success"
						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				niteoCF = getTarget()

				niteoCF.createStack stackName, "body"
					.done (data) ->
						if isSuccess
							numTimesProgressCalled.should.be.equal(numPolls)
						else
							assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						if !isSuccess
							numTimesProgressCalled.should.be.equal(numPolls)
						else
							assert.fail "There should not have been an exception thrown: #{err}"
						done()
					, (progress) ->
						numTimesProgressCalled++

			it 'should return an error if a stack is found with a failure status. (CREATE_FAILED, 1 Polls)', (done) ->

				createStackTestPolling "Test Stack", "CREATE_FAILED", 5, false, done

			it 'should return an error if a stack is found with a failure status. (CREATE_FAILED, 50 Polls)', (done) ->

				createStackTestPolling "Test Stack", "CREATE_FAILED", 50, false, done

			it 'should return an error if a stack is found with a failure status. (ROLLBACK_COMPLETE, 1 Polls)', (done) ->

				createStackTestPolling "Test Stack", "ROLLBACK_COMPLETE", 1, false, done

			it 'should return an error if a stack is found with a failure status. (ROLLBACK_COMPLETE, 50 Polls)', (done) ->

				createStackTestPolling "Test Stack", "ROLLBACK_COMPLETE", 50, false, done

			it 'should return an error if a stack is found with a failure status. (ROLLBACK_FAILED, 1 Polls)', (done) ->

				createStackTestPolling "Test Stack", "ROLLBACK_FAILED", 1, false, done

			it 'should return an error if a stack is found with a failure status. (ROLLBACK_FAILED, 50 Polls)', (done) ->

				createStackTestPolling "Test Stack", "ROLLBACK_FAILED", 50, false, done

			it 'should return success if a stack is found with a success status. (CREATE_COMPLETE, 1 Polls)', (done) ->

				createStackTestPolling "Test Stack", "CREATE_COMPLETE", 1, true, done

			it 'should return success if a stack is found with a success status. (CREATE_COMPLETE, 50 Polls)', (done) ->

				createStackTestPolling "Test Stack", "CREATE_COMPLETE", 50, true, done

			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				niteoCF = getTarget()
				niteoCF.createStack "stackName", "body", { Parameters: [ ] }
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()

		describe 'deleteStack', ->

			it 'should throw an exception if stackName is null.', (done) ->
				getTarget().deleteStack null
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined.', (done) ->
				getTarget().deleteStack undefined
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should raise an exception if an exception happens.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						deleteStack: (options, callback) ->
							callback "someException", null

				niteoCF = getTarget() 

				niteoCF.deleteStack "stackName"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()



			deleteStackTestPolling = (stackName, resultStackStatus, numPolls, isSuccess, done) ->
				stackQueue = [
					{
						Stacks: [
							StackName: stackName
							StackId: "Some Id"
							StackStatus: resultStackStatus
						]
					}
				]

				#	We loop through numPolls + 1 because the 'getStackId' takes an extra call to describeStacks.
				i = 0
				while i < numPolls + 1	
					i++
					stackQueue.push
						Stacks: [
							StackName: stackName
							StackId: "Some Id"
							StackStatus: "Some Pending Status"
						]

				numTimesProgressCalled = 0

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						deleteStack: (options, callback) ->
							callback null, "Success"
						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				niteoCF = getTarget()

				niteoCF.deleteStack stackName
					.done (data) ->
						if isSuccess
							numTimesProgressCalled.should.be.equal(numPolls)
						else
							assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						if !isSuccess
							numTimesProgressCalled.should.be.equal(numPolls)
						else
							assert.fail "There should not have been an exception thrown: #{err}"
						done()
					, (progress) ->
						numTimesProgressCalled++


			it 'should return an error if a stack is found with a failure status. (DELETE_FAILED, 1 Polls)', (done) ->

				deleteStackTestPolling "Test Stack", "DELETE_FAILED", 1, false, done

			it 'should return an error if a stack is found with a failure status. (DELETE_FAILED, 50 Polls)', (done) ->

				deleteStackTestPolling "Test Stack", "DELETE_FAILED", 50, false, done

			it 'should return success if a stack is found with a success status. (DELETE_COMPLETE, 1 Polls)', (done) ->

				deleteStackTestPolling "Test Stack", "DELETE_COMPLETE", 1, true, done

			it 'should return success if a stack is found with a success status. (DELETE_COMPLETE, 50 Polls)', (done) ->

				deleteStackTestPolling "Test Stack", "DELETE_COMPLETE", 50, true, done

			it 'should return success if a stack is found with a success status. (DELETE_SKIPPED, 1 Polls)', (done) ->

				deleteStackTestPolling "Test Stack", "DELETE_SKIPPED", 1, true, done

			it 'should return success if a stack is found with a success status. (DELETE_SKIPPED, 50 Polls)', (done) ->

				deleteStackTestPolling "Test Stack", "DELETE_SKIPPED", 50, true, done

			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				niteoCF = getTarget()
				niteoCF.deleteStack "stackName"
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()

		describe 'updateStack', ->

			it 'should throw an exception if stackName is null.', (done) ->
				getTarget().updateStack null, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined.', (done) ->
				getTarget().updateStack undefined, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is null.', (done) ->
				getTarget().updateStack "stackName", null
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is undefined.', (done) ->
				getTarget().updateStack "stackName", undefined
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should raise an exception if an exception happens.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						updateStack: (options, callback) ->
							callback "someException", null

				niteoCF = getTarget() 

				niteoCF.updateStack "stackName", "body"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()



			updateStackTestPolling = (stackName, resultStackStatus, numPolls, isSuccess, done) ->
				stackQueue = [
					{
						Stacks: [
							StackName: stackName
							StackId: "Some Id"
							StackStatus: resultStackStatus
						]
					}
				]

				#	We loop through numPolls + 1 because the 'getStackId' takes an extra call to describeStacks.
				i = 0
				while i < numPolls + 1	
					i++
					stackQueue.push
						Stacks: [
							StackName: stackName
							StackId: "Some Id"
							StackStatus: "Some Pending Status"
						]

				numTimesProgressCalled = 0

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						updateStack: (options, callback) ->
							callback null, "Success"
						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				niteoCF = getTarget()

				niteoCF.updateStack stackName, "body"
					.done (data) ->
						if isSuccess
							numTimesProgressCalled.should.be.equal(numPolls)
						else
							assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						if !isSuccess
							numTimesProgressCalled.should.be.equal(numPolls)
						else
							assert.fail "There should not have been an exception thrown: #{err}"
						done()
					, (progress) ->
						numTimesProgressCalled++


			it 'should return an error if a stack is found with a failure status. (UPDATE_ROLLBACK_FAILED, 1 Polls)', (done) ->

				updateStackTestPolling "Test Stack", "UPDATE_ROLLBACK_FAILED", 1, false, done

			it 'should return an error if a stack is found with a failure status. (UPDATE_ROLLBACK_FAILED, 50 Polls)', (done) ->

				updateStackTestPolling "Test Stack", "UPDATE_ROLLBACK_FAILED", 50, false, done

			it 'should return success if a stack is found with a success status. (UPDATE_ROLLBACK_COMPLETE, 1 Polls)', (done) ->

				updateStackTestPolling "Test Stack", "UPDATE_ROLLBACK_COMPLETE", 1, false, done

			it 'should return success if a stack is found with a success status. (UPDATE_ROLLBACK_COMPLETE, 50 Polls)', (done) ->

				updateStackTestPolling "Test Stack", "UPDATE_ROLLBACK_COMPLETE", 50, false, done

			it 'should return success if a stack is found with a success status. (UPDATE_COMPLETE, 1 Polls)', (done) ->

				updateStackTestPolling "Test Stack", "UPDATE_COMPLETE", 1, true, done

			it 'should return success if a stack is found with a success status. (UPDATE_COMPLETE, 50 Polls)', (done) ->

				updateStackTestPolling "Test Stack", "UPDATE_COMPLETE", 50, true, done

			it 'should still return a promise if an exception is encountered.', (done) ->

				AWS = 
					CloudFormation: class
						constructor: ->
							throw 'Some Random Error'

				niteoCF = getTarget()
				niteoCF.updateStack "stackName", "body"
					.catch (err) ->
						err.should.equal 'Some Random Error'
						done()
