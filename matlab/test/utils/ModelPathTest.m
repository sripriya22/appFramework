classdef ModelPathTest < matlab.unittest.TestCase
    % ModelPathTest - Unit tests for ModelPath class
    
    methods (Test)
        function testEmptyPath(testCase)
            % Test empty path refers to root
            mp = appFramework.utils.ModelPath("");
            
            testCase.verifyTrue(mp.isEmpty());
            testCase.verifyEqual(mp.numSegments(), 0);
            testCase.verifyEqual(mp.string(), "");
        end
        
        function testSimpleProperty(testCase)
            % Test single property path
            mp = appFramework.utils.ModelPath("Name");
            
            testCase.verifyFalse(mp.isEmpty());
            testCase.verifyEqual(mp.numSegments(), 1);
            testCase.verifyEqual(mp.Segments(1).Property, "Name");
            testCase.verifyEqual(mp.Segments(1).Index, 0);
        end
        
        function testNestedProperty(testCase)
            % Test nested property path
            mp = appFramework.utils.ModelPath("Parent.Child.Value");
            
            testCase.verifyEqual(mp.numSegments(), 3);
            testCase.verifyEqual(mp.Segments(1).Property, "Parent");
            testCase.verifyEqual(mp.Segments(2).Property, "Child");
            testCase.verifyEqual(mp.Segments(3).Property, "Value");
        end
        
        function testArrayIndex(testCase)
            % Test array indexing
            mp = appFramework.utils.ModelPath("Children[1]");
            
            testCase.verifyEqual(mp.numSegments(), 1);
            testCase.verifyEqual(mp.Segments(1).Property, "Children");
            testCase.verifyEqual(mp.Segments(1).Index, 1);
        end
        
        function testComplexPath(testCase)
            % Test complex path with arrays and nesting
            mp = appFramework.utils.ModelPath("Species[2].Parameters[1].Value");
            
            testCase.verifyEqual(mp.numSegments(), 3);
            testCase.verifyEqual(mp.Segments(1).Property, "Species");
            testCase.verifyEqual(mp.Segments(1).Index, 2);
            testCase.verifyEqual(mp.Segments(2).Property, "Parameters");
            testCase.verifyEqual(mp.Segments(2).Index, 1);
            testCase.verifyEqual(mp.Segments(3).Property, "Value");
            testCase.verifyEqual(mp.Segments(3).Index, 0);
        end
        
        function testResolveEmptyPath(testCase)
            % Test resolving empty path returns root
            root = struct('Name', 'Root');
            mp = appFramework.utils.ModelPath("");
            
            result = mp.resolve(root);
            
            testCase.verifyEqual(result, root);
        end
        
        function testResolveSimpleProperty(testCase)
            % Test resolving simple property
            root = testClasses.SimpleObject("TestName", 42, true, 1);
            mp = appFramework.utils.ModelPath("Name");
            
            result = mp.resolve(root);
            
            testCase.verifyEqual(result, "TestName");
        end
        
        function testResolveNestedObject(testCase)
            % Test resolving nested object
            parent = testClasses.ParentObject(1, "Parent");
            child = testClasses.ChildObject(101, "Child1", 10, "mg");
            parent.addChild(child);
            
            mp = appFramework.utils.ModelPath("Children[1]");
            result = mp.resolve(parent);
            
            testCase.verifyEqual(result, child);
        end
        
        function testResolveNestedProperty(testCase)
            % Test resolving nested property
            parent = testClasses.ParentObject(1, "Parent");
            child = testClasses.ChildObject(101, "ChildName", 10, "mg");
            parent.addChild(child);
            
            mp = appFramework.utils.ModelPath("Children[1].Name");
            result = mp.resolve(parent);
            
            testCase.verifyEqual(result, "ChildName");
        end
        
        function testResolveInvalidProperty(testCase)
            % Test error on invalid property
            root = testClasses.SimpleObject("Test", 1, true, 1);
            mp = appFramework.utils.ModelPath("InvalidProperty");
            
            testCase.verifyError(@() mp.resolve(root), 'appFramework:utils:InvalidPath');
        end
        
        function testResolveIndexOutOfBounds(testCase)
            % Test error on index out of bounds
            parent = testClasses.ParentObject(1, "Parent");
            mp = appFramework.utils.ModelPath("Children[1]");
            
            testCase.verifyError(@() mp.resolve(parent), 'appFramework:utils:IndexOutOfBounds');
        end
        
        function testInvalidBracketSyntax(testCase)
            % Test error on invalid bracket syntax
            testCase.verifyError(...
                @() appFramework.utils.ModelPath("Children[abc]"), ...
                'appFramework:utils:InvalidPathSyntax');
        end
        
        function testZeroIndexError(testCase)
            % Test error on 0 index (must be 1-based)
            testCase.verifyError(...
                @() appFramework.utils.ModelPath("Children[0]"), ...
                'appFramework:utils:InvalidIndex');
        end
        
        function testValidatePathString(testCase)
            % Test static validation method
            appFramework.utils.ModelPath.validatePathString("");
            appFramework.utils.ModelPath.validatePathString("Name");
            appFramework.utils.ModelPath.validatePathString("A.B.C");
            appFramework.utils.ModelPath.validatePathString("A[1].B[2]");
            
            testCase.verifyError(...
                @() appFramework.utils.ModelPath.validatePathString("A[1"), ...
                'appFramework:utils:UnmatchedBrackets');
        end
        
        function testCharConversion(testCase)
            % Test char conversion
            mp = appFramework.utils.ModelPath("Species[1].Name");
            
            testCase.verifyEqual(char(mp), 'Species[1].Name');
        end
    end
end
