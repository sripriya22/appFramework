classdef ProjectionMap < handle
    % ProjectionMap - Represents a projection map definition loaded from JSON
    %
    % This class parses a projection map JSON file and provides access to
    % the property definitions. It holds a weak reference to the 
    % ProjectionEngine to look up nested maps by MATLAB class name.
    %
    % Example:
    %   map = appFramework.projection.ProjectionMap(jsonFilePath);
    %   propNames = map.getPropertyNames();
    %   propDef = map.getPropertyDefinition("StartTime");
    
    properties (SetAccess = private)
        MATLABClass (1,1) string
        JSClass (1,1) string
        ReferenceIDProperty string = string.empty
        FilePath (1,1) string
        Properties dictionary = dictionary(string.empty, appFramework.projection.PropertyDefinition.empty)
    end
    
    properties (Access = private, WeakHandle)
        EngineRef (1,1) appFramework.projection.ProjectionEngine
    end
    
    methods
        function obj = ProjectionMap(jsonFilePath, engine)
            % ProjectionMap - Construct from a JSON file path
            %
            % Syntax:
            %   map = ProjectionMap(jsonFilePath, engine)
            %
            % Inputs:
            %   jsonFilePath - Full path to the projection map JSON file
            %   engine - ProjectionEngine that owns this map
            
            arguments
                jsonFilePath (1,1) string
                engine (1,1) appFramework.projection.ProjectionEngine
            end
            
            obj.FilePath = jsonFilePath;
            obj.EngineRef = engine;
            obj.Properties = dictionary(string.empty, appFramework.projection.PropertyDefinition.empty);
            
            obj.parseJsonFile(jsonFilePath);
        end
        
        function names = getPropertyNames(obj)
            % getPropertyNames - Get all property names in this map
            %
            % Returns:
            %   names - String array of property names
            
            names = keys(obj.Properties);
        end
        
        function propDef = getPropertyDefinition(obj, name)
            % getPropertyDefinition - Get the PropertyDefinition for a property
            %
            % Inputs:
            %   name - Property name (string)
            %
            % Returns:
            %   propDef - PropertyDefinition object
            %
            % Throws error if property not found
            
            arguments
                obj
                name (1,1) string
            end
            
            if ~isKey(obj.Properties, name)
                error('appFramework:projection:PropertyNotFound', ...
                    'Property "%s" not found in projection map for %s', ...
                    name, obj.MATLABClass);
            end
            
            propDef = obj.Properties(name);
        end
        
        function tf = hasProperty(obj, name)
            % hasProperty - Check if a property exists in this map
            %
            % Inputs:
            %   name - Property name (string)
            %
            % Returns:
            %   tf - True if property exists
            
            arguments
                obj
                name (1,1) string
            end
            
            tf = isKey(obj.Properties, name);
        end
        
        function nestedMap = getNestedMap(obj, matlabClassName)
            % getNestedMap - Get the ProjectionMap for a nested type by class name
            %
            % Queries the engine to get the map by MATLAB class name.
            % The Type field in property definitions now contains the full
            % MATLAB class name directly.
            %
            % Inputs:
            %   matlabClassName - MATLAB class name (from propDef.Type)
            %
            % Returns:
            %   nestedMap - ProjectionMap object for the nested type
            %
            % Throws error if engine not set or map not found
            
            arguments
                obj
                matlabClassName (1,1) string
            end
            
            if isempty(obj.EngineRef) || ~isvalid(obj.EngineRef)
                error('appFramework:projection:EngineNotSet', ...
                    'ProjectionEngine reference not set on ProjectionMap for %s', ...
                    obj.MATLABClass);
            end
            
            nestedMap = obj.EngineRef.getMap(matlabClassName);
        end
        
        function tf = hasNestedMap(obj, matlabClassName)
            % hasNestedMap - Check if a nested map exists for a class
            %
            % Inputs:
            %   matlabClassName - MATLAB class name
            %
            % Returns:
            %   tf - True if engine has a map for this class
            
            arguments
                obj
                matlabClassName (1,1) string
            end
            
            if isempty(obj.EngineRef) || ~isvalid(obj.EngineRef)
                tf = false;
                return;
            end
            
            tf = obj.EngineRef.hasMap(matlabClassName);
        end
        
        end
    
    methods (Access = private)
        function parseJsonFile(obj, jsonFilePath)
            % parseJsonFile - Parse the JSON file and populate properties
            
            if ~isfile(jsonFilePath)
                error('appFramework:projection:FileNotFound', ...
                    'Projection map file not found: %s', jsonFilePath);
            end
            
            jsonText = fileread(jsonFilePath);
            data = jsondecode(jsonText);
            
            if ~isfield(data, 'MATLABClass')
                error('appFramework:projection:MissingField', ...
                    'Projection map missing required field "MATLABClass": %s', jsonFilePath);
            end
            obj.MATLABClass = string(data.MATLABClass);
            
            if ~isfield(data, 'JSClass')
                error('appFramework:projection:MissingField', ...
                    'Projection map missing required field "JSClass": %s', jsonFilePath);
            end
            obj.JSClass = string(data.JSClass);
            
            if isfield(data, 'ReferenceIDProperty')
                refIdProp = data.ReferenceIDProperty;
                if ischar(refIdProp) || isstring(refIdProp)
                    obj.ReferenceIDProperty = string(refIdProp);
                elseif iscell(refIdProp)
                    obj.ReferenceIDProperty = string(refIdProp);
                else
                    obj.ReferenceIDProperty = string(refIdProp);
                end
            end
            
            if ~isfield(data, 'Properties')
                error('appFramework:projection:MissingField', ...
                    'Projection map missing required field "Properties": %s', jsonFilePath);
            end
            
            propNames = fieldnames(data.Properties);
            for i = 1:numel(propNames)
                propName = propNames{i};
                propStruct = data.Properties.(propName);
                propDef = appFramework.projection.PropertyDefinition.fromStruct(...
                    string(propName), propStruct);
                obj.Properties(string(propName)) = propDef;
            end
        end
    end
end
