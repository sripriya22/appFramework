classdef PropertyDefinition
    % PropertyDefinition - Value object representing a property definition in a projection map
    %
    % This class holds the metadata for a single property as defined in a
    % projection map JSON file. It is immutable after construction.
    %
    % Example:
    %   propDef = appFramework.projection.PropertyDefinition("StartTime", "double");
    %   propDef = appFramework.projection.PropertyDefinition("Species", "Species", ...
    %       IsArray=true, IsReference=false, ReadOnly=true);
    
    properties (SetAccess = immutable)
        Name (1,1) string
        Type (1,1) string
        IsArray (1,1) logical = false
        IsReference (1,1) logical = false
        ReadOnly (1,1) logical = false
        ClientReadOnly (1,1) logical = false
    end
    
    methods
        function obj = PropertyDefinition(name, type, options)
            % PropertyDefinition - Construct a PropertyDefinition
            %
            % Syntax:
            %   propDef = PropertyDefinition(name, type)
            %   propDef = PropertyDefinition(name, type, Name=Value)
            %
            % Inputs:
            %   name - Property name (string)
            %   type - Type name: primitive ("string", "double", "logical") 
            %          or projection map type name (string)
            %
            % Name-Value Arguments:
            %   IsArray - True if property is an array (default: false)
            %   IsReference - True if property holds references (default: false)
            %   ReadOnly - True if MATLAB property has SetAccess=private (default: false)
            %   ClientReadOnly - True if client should not modify (default: false)
            
            arguments
                name (1,1) string
                type (1,1) string
                options.IsArray (1,1) logical = false
                options.IsReference (1,1) logical = false
                options.ReadOnly (1,1) logical = false
                options.ClientReadOnly (1,1) logical = false
            end
            
            obj.Name = name;
            obj.Type = type;
            obj.IsArray = options.IsArray;
            obj.IsReference = options.IsReference;
            obj.ReadOnly = options.ReadOnly;
            obj.ClientReadOnly = options.ClientReadOnly;
        end
        
        function tf = isPrimitive(obj)
            % isPrimitive - Check if this property has a primitive type
            %
            % Returns true if Type is "string", "double", or "logical"
            
            tf = ismember(obj.Type, ["string", "double", "logical"]);
        end
    end
    
    methods (Static)
        function obj = fromStruct(name, propStruct)
            % fromStruct - Create PropertyDefinition from a parsed JSON struct
            %
            % Syntax:
            %   propDef = PropertyDefinition.fromStruct(name, propStruct)
            %
            % Inputs:
            %   name - Property name (string)
            %   propStruct - Struct with fields: Type, IsArray, IsReference, 
            %                ReadOnly, ClientReadOnly (all optional except Type)
            %
            % Example:
            %   s = struct('Type', 'double', 'ReadOnly', true);
            %   propDef = PropertyDefinition.fromStruct("StartTime", s);
            
            arguments
                name (1,1) string
                propStruct (1,1) struct
            end
            
            if ~isfield(propStruct, 'Type')
                error('appFramework:projection:MissingType', ...
                    'Property "%s" is missing required field "Type"', name);
            end
            
            type = string(propStruct.Type);
            
            isArray = false;
            if isfield(propStruct, 'IsArray')
                isArray = logical(propStruct.IsArray);
            end
            
            isReference = false;
            if isfield(propStruct, 'IsReference')
                isReference = logical(propStruct.IsReference);
            end
            
            readOnly = false;
            if isfield(propStruct, 'ReadOnly')
                readOnly = logical(propStruct.ReadOnly);
            end
            
            clientReadOnly = readOnly;
            if isfield(propStruct, 'ClientReadOnly')
                clientReadOnly = logical(propStruct.ClientReadOnly);
            end
            
            obj = appFramework.projection.PropertyDefinition(name, type, ...
                IsArray=isArray, ...
                IsReference=isReference, ...
                ReadOnly=readOnly, ...
                ClientReadOnly=clientReadOnly);
        end
    end
end
