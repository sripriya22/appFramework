classdef ProjectionMapTest < matlab.unittest.TestCase
    % ProjectionMapTest - Unit tests for ProjectionMap class
    
    properties (TestParameter)
        TestDataFolder = {fullfile(fileparts(mfilename('fullpath')), 'data')}
    end
    
    methods (Test)
        function testLoadSimpleObject(testCase, TestDataFolder)
            % Test loading a simple projection map
            jsonPath = fullfile(TestDataFolder, 'simple-object.json');
            engine = appFramework.projection.ProjectionEngine();
            
            map = appFramework.projection.ProjectionMap(jsonPath, engine);
            
            testCase.verifyEqual(map.MATLABClass, "testClasses.SimpleObject");
            testCase.verifyEqual(map.JSClass, "SimpleObject");
            testCase.verifyEqual(map.ReferenceIDProperty, "SessionID");
        end
        
        function testGetPropertyNames(testCase, TestDataFolder)
            % Test getting property names
            jsonPath = fullfile(TestDataFolder, 'simple-object.json');
            engine = appFramework.projection.ProjectionEngine();
            map = appFramework.projection.ProjectionMap(jsonPath, engine);
            
            propNames = map.getPropertyNames();
            
            testCase.verifyTrue(ismember("Name", propNames));
            testCase.verifyTrue(ismember("Value", propNames));
            testCase.verifyTrue(ismember("IsActive", propNames));
            testCase.verifyTrue(ismember("SessionID", propNames));
        end
        
        function testGetPropertyDefinition(testCase, TestDataFolder)
            % Test getting a property definition
            jsonPath = fullfile(TestDataFolder, 'simple-object.json');
            engine = appFramework.projection.ProjectionEngine();
            map = appFramework.projection.ProjectionMap(jsonPath, engine);
            
            propDef = map.getPropertyDefinition("Name");
            
            testCase.verifyEqual(propDef.Name, "Name");
            testCase.verifyEqual(propDef.Type, "string");
            testCase.verifyFalse(propDef.IsArray);
            testCase.verifyFalse(propDef.IsReference);
        end
        
        function testGetPropertyDefinitionNotFound(testCase, TestDataFolder)
            % Test error when property not found
            jsonPath = fullfile(TestDataFolder, 'simple-object.json');
            engine = appFramework.projection.ProjectionEngine();
            map = appFramework.projection.ProjectionMap(jsonPath, engine);
            
            testCase.verifyError(...
                @() map.getPropertyDefinition("NonExistent"), ...
                'appFramework:projection:PropertyNotFound');
        end
        
        function testHasProperty(testCase, TestDataFolder)
            % Test hasProperty method
            jsonPath = fullfile(TestDataFolder, 'simple-object.json');
            engine = appFramework.projection.ProjectionEngine();
            map = appFramework.projection.ProjectionMap(jsonPath, engine);
            
            testCase.verifyTrue(map.hasProperty("Name"));
            testCase.verifyFalse(map.hasProperty("NonExistent"));
        end
        
        function testLoadParentWithNestedTypes(testCase, TestDataFolder)
            % Test loading a map with nested object types
            jsonPath = fullfile(TestDataFolder, 'parent-object.json');
            engine = appFramework.projection.ProjectionEngine();
            map = appFramework.projection.ProjectionMap(jsonPath, engine);
            
            testCase.verifyEqual(map.MATLABClass, "testClasses.ParentObject");
            
            % Type field now contains the full MATLAB class name
            childrenDef = map.getPropertyDefinition("Children");
            testCase.verifyEqual(childrenDef.Type, "testClasses.ChildObject");
        end
        
        function testArrayAndReferenceProperties(testCase, TestDataFolder)
            % Test properties with IsArray and IsReference flags
            jsonPath = fullfile(TestDataFolder, 'parent-object.json');
            engine = appFramework.projection.ProjectionEngine();
            map = appFramework.projection.ProjectionMap(jsonPath, engine);
            
            childrenDef = map.getPropertyDefinition("Children");
            testCase.verifyTrue(childrenDef.IsArray);
            testCase.verifyFalse(childrenDef.IsReference);
            
            selectedDef = map.getPropertyDefinition("SelectedChildren");
            testCase.verifyTrue(selectedDef.IsArray);
            testCase.verifyTrue(selectedDef.IsReference);
        end
        
        function testFileNotFound(testCase)
            % Test error when file not found
            engine = appFramework.projection.ProjectionEngine();
            testCase.verifyError(...
                @() appFramework.projection.ProjectionMap('/nonexistent/path.json', engine), ...
                'appFramework:projection:FileNotFound');
        end
    end
end
