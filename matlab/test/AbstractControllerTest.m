classdef AbstractControllerTest < matlab.unittest.TestCase
    % AbstractControllerTest - Unit tests for AbstractController class
    
    properties
        Controller
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.Controller = testClasses.TestController();
        end
    end
    
    methods (Test)
        function testConstructor(testCase)
            % Test that controller initializes correctly
            testCase.verifyNotEmpty(testCase.Controller.ProjectionEngine);
            testCase.verifyFalse(testCase.Controller.testHasRootObject());
            testCase.verifyFalse(testCase.Controller.testIsConnected());
        end
        
        function testSetRootObject(testCase)
            % Test setting a valid root object
            obj = testClasses.SimpleObject("Test", 42, true, 1);
            
            testCase.Controller.testSetRootObject(obj);
            
            testCase.verifyTrue(testCase.Controller.testHasRootObject());
            
            % Verify RootObjectChanged event was sent
            log = testCase.Controller.testGetEventLog();
            testCase.verifyEqual(log{end}.EventName, "RootObjectChanged");
        end
        
        function testSetRootObjectInvalidClass(testCase)
            % Test error when setting object with no projection map
            obj = struct('Name', 'Test');
            
            testCase.verifyError(...
                @() testCase.Controller.testSetRootObject(obj), ...
                'appFramework:controller:UnknownRootClass');
        end
        
        function testResetRootObject(testCase)
            % Test resetting the root object
            obj = testClasses.SimpleObject("Test", 42, true, 1);
            testCase.Controller.testSetRootObject(obj);
            
            testCase.Controller.testResetRootObject();
            
            testCase.verifyFalse(testCase.Controller.testHasRootObject());
        end
        
        function testResolveObjectRoot(testCase)
            % Test resolving root object
            obj = testClasses.SimpleObject("TestName", 42.5, true, 123);
            testCase.Controller.testSetRootObject(obj);
            
            resolved = testCase.Controller.testResolveObject("");
            
            testCase.verifyEqual(resolved, obj);
        end
        
        function testResolveObjectNested(testCase)
            % Test resolving nested object
            parent = testClasses.ParentObject(1, "Parent");
            child = testClasses.ChildObject(101, "Child1", 10, "mg");
            parent.addChild(child);
            testCase.Controller.testSetRootObject(parent);
            
            resolved = testCase.Controller.testResolveObject("Children[1]");
            
            testCase.verifyEqual(resolved, child);
        end
        
        function testResolveAndAccessProperty(testCase)
            % Test resolving object and accessing properties directly
            obj = testClasses.SimpleObject("TestName", 42.5, true, 123);
            testCase.Controller.testSetRootObject(obj);
            
            resolved = testCase.Controller.testResolveObject("");
            
            testCase.verifyEqual(resolved.Name, "TestName");
            testCase.verifyEqual(resolved.Value, 42.5);
        end
        
        function testResolveAndSetProperty(testCase)
            % Test resolving object and setting properties directly
            obj = testClasses.SimpleObject("Original", 10, true, 1);
            testCase.Controller.testSetRootObject(obj);
            
            resolved = testCase.Controller.testResolveObject("");
            resolved.Name = "Updated";
            resolved.Value = 99;
            
            testCase.verifyEqual(obj.Name, "Updated");
            testCase.verifyEqual(obj.Value, 99);
        end
        
        function testResolveNestedObject(testCase)
            % Test resolving nested object and accessing properties
            parent = testClasses.ParentObject(1, "Parent");
            child = testClasses.ChildObject(101, "Child1", 10, "mg");
            parent.addChild(child);
            testCase.Controller.testSetRootObject(parent);
            
            resolved = testCase.Controller.testResolveObject("Children[1]");
            
            testCase.verifyEqual(resolved.Name, "Child1");
        end
        
        function testResolveAndSetNestedProperty(testCase)
            % Test resolving nested object and setting properties
            parent = testClasses.ParentObject(1, "Parent");
            child = testClasses.ChildObject(101, "Child1", 10, "mg");
            parent.addChild(child);
            testCase.Controller.testSetRootObject(parent);
            
            resolved = testCase.Controller.testResolveObject("Children[1]");
            resolved.Value = 999;
            
            testCase.verifyEqual(parent.Children(1).Value, 999);
        end
        
        function testResolveNoRootObject(testCase)
            % Test error when no root object is set
            testCase.verifyError(...
                @() testCase.Controller.testResolveObject(""), ...
                'appFramework:controller:NoRootObject');
        end
        
        function testToJSON(testCase)
            % Test converting root object to JSON
            obj = testClasses.SimpleObject("Test", 42, true, 123);
            testCase.Controller.testSetRootObject(obj);
            
            result = testCase.Controller.testToJSON();
            
            testCase.verifyEqual(result.Name, "Test");
            testCase.verifyEqual(result.Value, 42);
            testCase.verifyEqual(result.IsActive, true);
            testCase.verifyEqual(result.SessionID, 123);
        end
        
        function testToJSONWithSubset(testCase)
            % Test converting with property subset
            obj = testClasses.SimpleObject("Test", 42, true, 123);
            testCase.Controller.testSetRootObject(obj);
            
            result = testCase.Controller.testToJSON(["Name", "Value"]);
            
            testCase.verifyEqual(result.Name, "Test");
            testCase.verifyEqual(result.Value, 42);
            testCase.verifyFalse(isfield(result, 'IsActive'));
        end
        
        function testNotifyUILogsEvents(testCase)
            % Test that notifyUI logs events in standalone mode
            testCase.Controller.testClearEventLog();
            testCase.Controller.testNotifyUI("TestEvent", struct('value', 42));
            testCase.Controller.testNotifyUI("AnotherEvent", struct('name', "test"));
            
            log = testCase.Controller.testGetEventLog();
            
            testCase.verifyEqual(numel(log), 2);
            testCase.verifyEqual(log{1}.EventName, "TestEvent");
            testCase.verifyEqual(log{1}.Data.value, 42);
            testCase.verifyEqual(log{2}.EventName, "AnotherEvent");
        end
        
        function testClearEventLog(testCase)
            % Test clearing the event log
            testCase.Controller.testNotifyUI("Event1", struct());
            testCase.Controller.testNotifyUI("Event2", struct());
            
            testCase.Controller.testClearEventLog();
            
            testCase.verifyEmpty(testCase.Controller.testGetEventLog());
        end
        
        function testSimulateEventDispatch(testCase)
            % Test that simulateEvent dispatches to handler methods
            obj = testClasses.SimpleObject("Original", 10, true, 1);
            testCase.Controller.testSetRootObject(obj);
            testCase.Controller.testClearEventLog();
            
            testCase.Controller.simulateEvent('UpdateName', struct('Value', 'NewName'));
            
            testCase.verifyEqual(obj.Name, "NewName");
            
            % Verify response event was sent
            log = testCase.Controller.testGetEventLog();
            testCase.verifyEqual(log{end}.EventName, "DispatchResponse");
            testCase.verifyEqual(log{end}.Data.Results.Name, "NewName");
        end
        
        function testSimulateEventGetModel(testCase)
            % Test the GetModel event handler
            obj = testClasses.SimpleObject("Test", 42, true, 123);
            testCase.Controller.testSetRootObject(obj);
            testCase.Controller.testClearEventLog();
            
            testCase.Controller.simulateEvent('GetModel', struct());
            
            log = testCase.Controller.testGetEventLog();
            testCase.verifyEqual(log{end}.EventName, "DispatchResponse");
            testCase.verifyEqual(log{end}.Data.Results.Model.Name, "Test");
        end
        
        function testDispatchUnknownMethod(testCase)
            % Test error when handler method not found
            testCase.verifyError(...
                @() testCase.Controller.simulateEvent('NonExistentMethod', struct()), ...
                'appFramework:controller:MethodNotFound');
        end
        
        function testDispatchToModelObject(testCase)
            % Test dispatch with ObjectPath targeting model object
            parent = testClasses.ParentObject(1, "Parent");
            child = testClasses.ChildObject(101, "Child1", 10, "mg");
            parent.addChild(child);
            testCase.Controller.testSetRootObject(parent);
            testCase.Controller.testClearEventLog();
            
            % Dispatch to handleSetUnits on the child object
            event = struct('EventType', 'SetUnits', 'ObjectPath', 'Children[1]', ...
                'Args', struct('NewUnits', 'g'));
            testCase.Controller.testDispatch(event);
            
            log = testCase.Controller.testGetEventLog();
            testCase.verifyEqual(log{end}.EventName, "DispatchResponse");
            testCase.verifyEqual(child.Units, "g");
        end
    end
end
