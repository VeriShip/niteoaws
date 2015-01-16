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

				localSetup()
				numTimesProgressCalled = 0

				resources = generateTestStacks 5, 10

				AWS = 
					CloudFormation: class
						describeStacks: (options, callback) ->
							callback null, resources.pop()

				verishipCF = getTarget()

				verishipCF.getResources()
					.done (data) ->
							data.length.should.be.equal(50)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()


			it 'should return 100 resources when there are 2 pages with 50 items per page.', (done) ->

				localSetup()
				numTimesProgressCalled = 0

				resources = generateTestStacks 2, 50

				AWS = 
					CloudFormation: class
						describeStacks: (options, callback) ->
							callback null, resources.pop()

				verishipCF = getTarget()

				verishipCF.getResources()
					.done (data) ->
							data.length.should.be.equal(100)
							done()
						, (err) ->
							assert.fail 'An error should not have been thrown.'
							done()

		describe 'validateTemplate', ->

			localSetup()
			verishipCF = getTarget() 

			it 'should throw an exception if templateBody is null', (done) ->

				verishipCF.validateTemplate null, "body"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should throw an exception if templateBody is undefined', (done) ->

				verishipCF.validateTemplate niteoaws.undefinedMethod, "body"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should throw an exception if the template is not valid.', (done) ->

				localSetup()
				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						validateTemplate: (body, callback) ->
							callback "Random Error", null
							
				verishipCF = getTarget()

				content = "{ }"
				verishipCF.validateTemplate(content, "us-west-2")
					.done	(data) ->
							assert.fail 'An error was expected.'
							done()
						, (err) ->
							done()

			it 'should show success if the template is valid.', (done) ->

				localSetup()
				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						validateTemplate: (body, callback) ->
							callback null, "Success"
							
				verishipCF = getTarget()

				content = "{ }"
				verishipCF.validateTemplate(content, "us-west-2")
					.done	(data) ->
							done()
						, (err) ->
							assert.fail 'The template should be valid.'
							done()

		describe 'doesStackExist', ->

			localSetup()
			verishipCF = getTarget() 

			it 'should throw an exception if stackName is null', (done) ->
				verishipCF.doesStackExist null, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined', (done) ->
				verishipCF.doesStackExist verishipCF.somethingUndefined, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should return true if the stack exists.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [
									StackName: options.StackName
								]

				verishipCF = getTarget()

				verishipCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.true
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return true if the stack exists. (mutiple stacks returned.)', (done) ->
				localSetup()

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

				verishipCF = getTarget()

				verishipCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.true
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()

			it 'should return false if the stack does not exist. (no stacks returned.)', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [ ]

				verishipCF = getTarget()

				verishipCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.false
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return false if the stack does not exist. (stacks returned but stack queried was not found.)', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [
									{ StackName: "Some Random Stack" }
								]

				verishipCF = getTarget()

				verishipCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.false
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return false if the stack does not exist. (Stacks is undefined)', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, { }

				verishipCF = getTarget()

				verishipCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.false
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()
			it 'should return an error if an error occured.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback "Some Error", null

				verishipCF = getTarget()

				verishipCF.doesStackExist("TestStackName", "TestRegion")
					.done (data) ->
						assert.fail 'An error should have been raised.'
						done()
					, (err) ->
						done()

		describe 'getStackId', ->

			localSetup()
			verishipCF = getTarget() 

			it 'should throw an exception if stackName is null', (done) ->
				verishipCF.getStackId null, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined', (done) ->
				verishipCF.getStackId verishipCF.somethingUndefined, "region" 
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should return stackId if the stack exists.', (done) ->
				
				localSetup()
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

				verishipCF = getTarget()

				verishipCF.getStackId("TestStackName", "TestRegion")
					.done (data) ->
						data.should.be.equal expectedStackId	
						done()
					, (err) ->
						assert.fail 'An error should not have been thrown here.'
						done()

			it 'should return error if the stack is not found.', (done) ->
				
				localSetup()
				expectedStackId = "Test Stack Id"

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, 
								Stacks: [ ]

				verishipCF = getTarget()

				verishipCF.getStackId("TestStackName", "TestRegion")
					.done (data) ->
						assert.fail 'An error should have been thrown here.'
						done()
					, (err) ->
						done()

			it 'should return error if an error occured.', (done) ->
				
				localSetup()
				expectedStackId = "Test Stack Id"

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback "Some Error", null

				verishipCF = getTarget()

				verishipCF.getStackId("TestStackName", "TestRegion")
					.done (data) ->
						assert.fail 'An error should have been thrown here.'
						done()
					, (err) ->
						done()

		describe 'pollStackStatus', ->

			localSetup()
			verishipCF = getTarget()

			it 'should throw an exception if stackId is null.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus(null, [ "" ], [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if stackId is undefined.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus(undefined, [ "" ], [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if successStatuses is null.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus("stackId", null, [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if successStatuses is undefined.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus("stackId", undefined, [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if successStatuses is empty.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus("stackId", [ ], [ "" ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if failureStatuses is null.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus("stackId", [ "" ], null, deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if failureStatuses is undefined.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus("stackId", [ "" ], undefined, deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()
			it 'should throw an exception if failureStatuses is empty.', (done) ->
				deferred = Q.defer()
				verishipCF.pollStackStatus("stackId", [ "" ], [ ], deferred)
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return an error if one is encountered.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback "Some Error", null	

				verishipCF = getTarget()
				deferred = Q.defer()

				verishipCF.pollStackStatus "stackId", [ "" ], [ "" ], deferred
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return an error if no stacks are found.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null,
								Stacks: [ ] 

				verishipCF = getTarget()
				deferred = Q.defer()

				verishipCF.pollStackStatus "stackId", [ "" ], [ "" ], deferred
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return an error if a stack is found with a failure status.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null,
								Stacks: [ 
									StackId: "stackId"
									StackStatus: "Some Failure Status"
								] 

				verishipCF = getTarget()
				deferred = Q.defer()

				verishipCF.pollStackStatus "stackId", [ "" ], [ "Some Failure Status" ], deferred
				deferred.promise
					.done (data) ->
						assert.fail 'There should have been an exception thrown.'
						done()
					, (err) ->
						done()

			it 'should return success if a stack is found with a success status.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null,
								Stacks: [ 
									StackId: "stackId"
									StackStatus: "Some Success Status"
								] 

				verishipCF = getTarget()
				deferred = Q.defer()

				verishipCF.pollStackStatus "stackId", [ "Some Success Status" ], [ "Some Failure" ], deferred
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

				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				verishipCF = getTarget()
				deferred = Q.defer()

				verishipCF.pollStackStatus targetStackId, [ "" ], failureStatuses, deferred
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

				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				verishipCF = getTarget()
				deferred = Q.defer()

				verishipCF.pollStackStatus targetStackId, successStatuses, [ "" ], deferred
				deferred.promise
					.done (data) ->
						done()
					, (err) ->
						assert.fail 'There should not have been an exception thrown.'
						done()

		describe 'createStack', ->

			localSetup()
			verishipCF = getTarget() 

			it 'should throw an exception if stackName is null.', (done) ->
				verishipCF.createStack null, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined.', (done) ->
				verishipCF.createStack undefined, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is null.', (done) ->
				verishipCF.createStack "stackName", null
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is undefined.', (done) ->
				verishipCF.createStack "stackName", undefined
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should raise an exception if an exception happens.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						createStack: (options, callback) ->
							callback "someException", null

				verishipCF = getTarget() 

				verishipCF.createStack "stackName", "body", { Parameters: [ ] }
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

				localSetup()
				numTimesProgressCalled = 0

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						createStack: (options, callback) ->
							callback null, "Success"
						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				verishipCF = getTarget()

				verishipCF.createStack stackName, "body"
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

		describe 'deleteStack', ->

			localSetup()
			verishipCF = getTarget() 

			it 'should throw an exception if stackName is null.', (done) ->
				verishipCF.deleteStack null
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined.', (done) ->
				verishipCF.deleteStack undefined
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should raise an exception if an exception happens.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						deleteStack: (options, callback) ->
							callback "someException", null

				verishipCF = getTarget() 

				verishipCF.deleteStack "stackName"
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

				localSetup()
				numTimesProgressCalled = 0

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						deleteStack: (options, callback) ->
							callback null, "Success"
						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				verishipCF = getTarget()

				verishipCF.deleteStack stackName
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

		describe 'updateStack', ->

			localSetup()
			verishipCF = getTarget() 

			it 'should throw an exception if stackName is null.', (done) ->
				verishipCF.updateStack null, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if stackName is undefined.', (done) ->
				verishipCF.updateStack undefined, "templateBody"
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is null.', (done) ->
				verishipCF.updateStack "stackName", null
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()
			it 'should throw an exception if templateBody is undefined.', (done) ->
				verishipCF.updateStack "stackName", undefined
					.done (data) ->
							assert.fail 'There should have been an exception thrown.'
							done()
						, (err) ->
							done()

			it 'should raise an exception if an exception happens.', (done) ->
				localSetup()

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						updateStack: (options, callback) ->
							callback "someException", null

				verishipCF = getTarget() 

				verishipCF.updateStack "stackName", "body"
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

				localSetup()
				numTimesProgressCalled = 0

				AWS = 
					CloudFormation: class
						constructor: (@region) ->

						updateStack: (options, callback) ->
							callback null, "Success"
						describeStacks: (options, callback) ->
							callback null, stackQueue.pop()	

				verishipCF = getTarget()

				verishipCF.updateStack stackName, "body"
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
