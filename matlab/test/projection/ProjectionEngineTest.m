classdef ProjectionEngineTest < matlab.unittest.TestCase
    % ProjectionEngineTest - Unit tests for ProjectionEngine class
    
    properties
        TestDataFolder
        Engine
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.TestDataFolder = fullfile(fileparts(mfilename('fullpath')), '..', 'data');
            testCase.Engine = appFramework.projection.ProjectionEngine(testCase.TestDataFolder);
        end
    end
    
    methods (Test)
        function testLoadMaps(testCase)
            % Test that maps are loaded correctly
            testCase.verifyTrue(testCase.Engine.hasMap("testClasses.SimpleObject"));
            testCase.verifyTrue(testCase.Engine.hasMap("testClasses.ChildObject"));
            testCase.verifyTrue(testCase.Engine.hasMap("testClasses.ParentObject"));
        end
        
        function testGetMap(testCase)
            % Test getting a map by class name
            map = testCase.Engine.getMap("testClasses.SimpleObject");
            
            testCase.verifyEqual(map.MATLABClass, "testClasses.SimpleObject");
            testCase.verifyEqual(map.JSClass, "SimpleObject");
        end
        
        function testGetMapNotFound(testCase)
            % Test error when map not found
            testCase.verifyError(...
                @() testCase.Engine.getMap("NonExistent.Class"), ...
                'appFramework:projection:MapNotFound');
        end
        
        function testToJSONSimpleObject(testCase)
            % Test converting a simple object to JSON
            obj = testClasses.SimpleObject("TestName", 42.5, true, 12345);
            
            result = testCase.Engine.toJSON(obj);
            
            testCase.verifyEqual(result.Name, "TestName");
            testCase.verifyEqual(result.Value, 42.5);
            testCase.verifyEqual(result.IsActive, true);
            testCase.verifyEqual(result.SessionID, 12345);
        end
        
        function testToJSONWithPropertySubset(testCase)
            % Test converting with a property subset
            obj = testClasses.SimpleObject("TestName", 42.5, true, 12345);
            
            result = testCase.Engine.toJSON(obj, ["Name", "Value"]);
            
            testCase.verifyEqual(result.Name, "TestName");
            testCase.verifyEqual(result.Value, 42.5);
            testCase.verifyFalse(isfield(result, 'IsActive'));
            testCase.verifyFalse(isfield(result, 'SessionID'));
        end
        
        function testToJSONWithNestedObjects(testCase)
            % Test converting an object with nested objects
            parent = testClasses.ParentObject(1, "Parent1");
            child1 = testClasses.ChildObject(101, "Child1", 10, "mg");
            child2 = testClasses.ChildObject(102, "Child2", 20, "kg");
            parent.addChild(child1);
            parent.addChild(child2);
            
            result = testCase.Engine.toJSON(parent);
            
            testCase.verifyEqual(result.SessionID, 1);
            testCase.verifyEqual(result.Name, "Parent1");
            testCase.verifyEqual(numel(result.Children), 2);
            testCase.verifyEqual(result.Children(1).SessionID, 101);
            testCase.verifyEqual(result.Children(1).Name, "Child1");
            testCase.verifyEqual(result.Children(2).SessionID, 102);
            testCase.verifyEqual(result.Children(2).Name, "Child2");
        end
        
        function testToJSONWithReferences(testCase)
            % Test converting an object with reference properties
            parent = testClasses.ParentObject(1, "Parent1");
            child1 = testClasses.ChildObject(101, "Child1", 10, "mg");
            child2 = testClasses.ChildObject(102, "Child2", 20, "kg");
            parent.addChild(child1);
            parent.addChild(child2);
            parent.selectChild(child1);
            
            result = testCase.Engine.toJSON(parent);
            
            testCase.verifyEqual(numel(result.SelectedChildren), 1);
            testCase.verifyEqual(result.SelectedChildren(1).SessionID, 101);
            testCase.verifyFalse(isfield(result.SelectedChildren(1), 'Name'));
            testCase.verifyFalse(isfield(result.SelectedChildren(1), 'Value'));
        end
        
        function testToJSONEmptyArrays(testCase)
            % Test converting an object with empty arrays
            parent = testClasses.ParentObject(1, "Parent1");
            
            result = testCase.Engine.toJSON(parent);
            
            testCase.verifyEmpty(result.Children);
            testCase.verifyEmpty(result.SelectedChildren);
        end
        
        function testToJSONMissingPropertyError(testCase)
            % Test error when source object is missing a property
            obj = struct('Name', 'Test');
            
            testCase.verifyError(...
                @() testCase.Engine.toJSON(obj), ...
                'appFramework:projection:MapNotFound');
        end
        
        function testInvalidPropertySubsetError(testCase)
            % Test error when property subset contains invalid property
            obj = testClasses.SimpleObject("Test", 1, true, 1);
            
            testCase.verifyError(...
                @() testCase.Engine.toJSON(obj, ["Name", "InvalidProp"]), ...
                'appFramework:projection:InvalidPropertySubset');
        end
        
        function testNestedMapsResolved(testCase)
            % Test that nested maps are properly resolved via engine
            parentMap = testCase.Engine.getMap("testClasses.ParentObject");
            
            % Type now contains the full MATLAB class name
            testCase.verifyTrue(parentMap.hasNestedMap("testClasses.ChildObject"));
            
            childMap = parentMap.getNestedMap("testClasses.ChildObject");
            testCase.verifyEqual(childMap.MATLABClass, "testClasses.ChildObject");
        end
        
        function testJsonEncodeCompatibility(testCase)
            % Test that output can be passed to jsonencode
            parent = testClasses.ParentObject(1, "Parent1");
            child1 = testClasses.ChildObject(101, "Child1", 10, "mg");
            parent.addChild(child1);
            parent.selectChild(child1);
            
            result = testCase.Engine.toJSON(parent);
            
            jsonStr = jsonencode(result);
            testCase.verifyTrue(ischar(jsonStr) || isstring(jsonStr));
            testCase.verifyTrue(contains(jsonStr, '"SessionID":1'));
            testCase.verifyTrue(contains(jsonStr, '"Name":"Parent1"'));
        end
    end
end
