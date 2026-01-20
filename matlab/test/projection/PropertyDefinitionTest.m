classdef PropertyDefinitionTest < matlab.unittest.TestCase
    % PropertyDefinitionTest - Unit tests for PropertyDefinition class
    
    methods (Test)
        function testConstructorWithDefaults(testCase)
            % Test basic construction with only required arguments
            propDef = appFramework.projection.PropertyDefinition("StartTime", "double");
            
            testCase.verifyEqual(propDef.Name, "StartTime");
            testCase.verifyEqual(propDef.Type, "double");
            testCase.verifyFalse(propDef.IsArray);
            testCase.verifyFalse(propDef.IsReference);
            testCase.verifyFalse(propDef.ReadOnly);
            testCase.verifyFalse(propDef.ClientReadOnly);
        end
        
        function testConstructorWithAllOptions(testCase)
            % Test construction with all optional arguments
            propDef = appFramework.projection.PropertyDefinition("Species", "Species", ...
                IsArray=true, ...
                IsReference=true, ...
                ReadOnly=true, ...
                ClientReadOnly=true);
            
            testCase.verifyEqual(propDef.Name, "Species");
            testCase.verifyEqual(propDef.Type, "Species");
            testCase.verifyTrue(propDef.IsArray);
            testCase.verifyTrue(propDef.IsReference);
            testCase.verifyTrue(propDef.ReadOnly);
            testCase.verifyTrue(propDef.ClientReadOnly);
        end
        
        function testIsPrimitiveWithDouble(testCase)
            propDef = appFramework.projection.PropertyDefinition("Value", "double");
            testCase.verifyTrue(propDef.isPrimitive());
        end
        
        function testIsPrimitiveWithString(testCase)
            propDef = appFramework.projection.PropertyDefinition("Name", "string");
            testCase.verifyTrue(propDef.isPrimitive());
        end
        
        function testIsPrimitiveWithLogical(testCase)
            propDef = appFramework.projection.PropertyDefinition("Flag", "logical");
            testCase.verifyTrue(propDef.isPrimitive());
        end
        
        function testIsPrimitiveWithCustomType(testCase)
            propDef = appFramework.projection.PropertyDefinition("Model", "Model");
            testCase.verifyFalse(propDef.isPrimitive());
        end
        
        function testFromStructMinimal(testCase)
            % Test fromStruct with only Type field
            s = struct('Type', 'double');
            propDef = appFramework.projection.PropertyDefinition.fromStruct("StartTime", s);
            
            testCase.verifyEqual(propDef.Name, "StartTime");
            testCase.verifyEqual(propDef.Type, "double");
            testCase.verifyFalse(propDef.IsArray);
            testCase.verifyFalse(propDef.IsReference);
            testCase.verifyFalse(propDef.ReadOnly);
            testCase.verifyFalse(propDef.ClientReadOnly);
        end
        
        function testFromStructComplete(testCase)
            % Test fromStruct with all fields
            s = struct(...
                'Type', 'Species', ...
                'IsArray', true, ...
                'IsReference', true, ...
                'ReadOnly', true, ...
                'ClientReadOnly', false);
            propDef = appFramework.projection.PropertyDefinition.fromStruct("SelectedSpecies", s);
            
            testCase.verifyEqual(propDef.Name, "SelectedSpecies");
            testCase.verifyEqual(propDef.Type, "Species");
            testCase.verifyTrue(propDef.IsArray);
            testCase.verifyTrue(propDef.IsReference);
            testCase.verifyTrue(propDef.ReadOnly);
            testCase.verifyFalse(propDef.ClientReadOnly);
        end
        
        function testFromStructClientReadOnlyDefaultsToReadOnly(testCase)
            % Test that ClientReadOnly defaults to ReadOnly value
            s = struct('Type', 'double', 'ReadOnly', true);
            propDef = appFramework.projection.PropertyDefinition.fromStruct("Value", s);
            
            testCase.verifyTrue(propDef.ReadOnly);
            testCase.verifyTrue(propDef.ClientReadOnly);
        end
        
        function testFromStructMissingTypeThrowsError(testCase)
            % Test that missing Type field throws an error
            s = struct('IsArray', true);
            
            testCase.verifyError(...
                @() appFramework.projection.PropertyDefinition.fromStruct("BadProp", s), ...
                'appFramework:projection:MissingType');
        end
        
        function testImmutability(testCase)
            % Test that properties cannot be modified after construction
            propDef = appFramework.projection.PropertyDefinition("Test", "double");
            
            testCase.verifyError(@() setName(propDef), 'MATLAB:class:SetProhibited');
            
            function setName(p)
                p.Name = "Changed";
            end
        end
    end
end
