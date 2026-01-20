classdef ProjectionMapTest < matlab.unittest.TestCase
    % ProjectionMapTest - Unit tests for ProjectionMap class
    
    properties (TestParameter)
        TestDataFolder = {fullfile(fileparts(mfilename('fullpath')), '..', 'data')}
    end
    
    methods (Test)
        function testLoadSimpleObject(testCase, TestDataFolder)
            % Test loading a simple projection map
            jsonPath = fullfile(TestDataFolder, 'simple-object.json');
            engine = appFramework.projection.ProjectionEngine(TestDataFolder);
            
            map = engine.getMap("testClasses.SimpleObject");
            
            testCase.verifyEqual(map.MATLABClass, "testClasses.SimpleObject");
            testCase.verifyEqual(map.JSClass, "SimpleObject");
            testCase.verifyEqual(map.ReferenceIDProperty, "SessionID");
        end
        
        function testGetPropertyNames(testCase, TestDataFolder)
            % Test getting property names
            engine = appFramework.projection.ProjectionEngine(TestDataFolder);
            map = engine.getMap("testClasses.SimpleObject");
            
            propNames = map.getPropertyNames();
            
            testCase.verifyTrue(ismember("Name", propNames));
            testCase.verifyTrue(ismember("Value", propNames));
            testCase.verifyTrue(ismember("IsActive", propNames));
            testCase.verifyTrue(ismember("SessionID", propNames));
        end
        
        function testGetPropertyDefinition(testCase, TestDataFolder)
            % Test getting a property definition
            engine = appFramework.projection.ProjectionEngine(TestDataFolder);
            map = engine.getMap("testClasses.SimpleObject");
            
            propDef = map.getPropertyDefinition("Name");
            
            testCase.verifyEqual(propDef.Name, "Name");
            testCase.verifyEqual(propDef.Type, "string");
            testCase.verifyFalse(propDef.IsArray);
            testCase.verifyFalse(propDef.IsReference);
        end
        
        function testGetPropertyDefinitionNotFound(testCase, TestDataFolder)
            % Test error when property not found
            engine = appFramework.projection.ProjectionEngine(TestDataFolder);
            map = engine.getMap("testClasses.SimpleObject");
            
            testCase.verifyError(...
                @() map.getPropertyDefinition("NonExistent"), ...
                'appFramework:projection:PropertyNotFound');
        end
        
        function testHasProperty(testCase, TestDataFolder)
            % Test hasProperty method
            engine = appFramework.projection.ProjectionEngine(TestDataFolder);
            map = engine.getMap("testClasses.SimpleObject");
            
            testCase.verifyTrue(map.hasProperty("Name"));
            testCase.verifyFalse(map.hasProperty("NonExistent"));
        end
        
        function testLoadParentWithNestedTypes(testCase, TestDataFolder)
            % Test loading a map with nested object types
            engine = appFramework.projection.ProjectionEngine(TestDataFolder);
            map = engine.getMap("testClasses.ParentObject");
            
            testCase.verifyEqual(map.MATLABClass, "testClasses.ParentObject");
            
            % Type field now contains the full MATLAB class name
            childrenDef = map.getPropertyDefinition("Children");
            testCase.verifyEqual(childrenDef.Type, "testClasses.ChildObject");
        end
        
        function testArrayAndReferenceProperties(testCase, TestDataFolder)
            % Test properties with IsArray and IsReference flags
            engine = appFramework.projection.ProjectionEngine(TestDataFolder);
            map = engine.getMap("testClasses.ParentObject");
            
            childrenDef = map.getPropertyDefinition("Children");
            testCase.verifyTrue(childrenDef.IsArray);
            testCase.verifyFalse(childrenDef.IsReference);
            
            selectedDef = map.getPropertyDefinition("SelectedChildren");
            testCase.verifyTrue(selectedDef.IsArray);
            testCase.verifyTrue(selectedDef.IsReference);
        end
        
        function testFolderNotFound(testCase)
            % Test error when folder not found
            testCase.verifyError(...
                @() appFramework.projection.ProjectionEngine('/nonexistent/path'), ...
                'appFramework:projection:FolderNotFound');
        end
    end
end
