classdef ProjectionEngine < handle
    % ProjectionEngine - Main engine for loading projection maps and converting objects to JSON
    %
    % This class manages a library of ProjectionMap objects and provides
    % methods to convert MATLAB objects to JSON-compatible structs.
    %
    % Example:
    %   engine = appFramework.projection.ProjectionEngine(fullfile(pwd, 'shared', 'model-projection'));
    %   jsonStruct = engine.toJSON(analysisObj);
    %   jsonString = jsonencode(jsonStruct);
    
    properties (SetAccess = private)
        Maps dictionary = dictionary(string.empty, cell.empty)
    end
    
    methods
        function obj = ProjectionEngine(folderPath)
            % ProjectionEngine - Construct a ProjectionEngine and load maps
            %
            % Inputs:
            %   folderPath - Path to folder containing projection map JSON files
            
            arguments
                folderPath (1,1) string
            end
            
            obj.Maps = dictionary(string.empty, cell.empty);
            obj.loadMaps(folderPath);
        end
    end
    
    methods (Access = private)
        function loadMaps(obj, folderPath)
            % loadMaps - Load all projection map JSON files from a folder
            %
            % Syntax:
            %   engine.loadMaps(folderPath)
            %
            % Inputs:
            %   folderPath - Path to folder containing projection map JSON files
            %
            % This method:
            %   1. Reads all .json files in the folder
            %   2. Creates ProjectionMap objects for each
            %   3. Sets engine reference on each map for nested lookups
            
            arguments
                obj
                folderPath (1,1) string
            end
            
            if ~isfolder(folderPath)
                error('appFramework:projection:FolderNotFound', ...
                    'Projection maps folder not found: %s', folderPath);
            end
            
            jsonFiles = dir(fullfile(folderPath, '*.json'));
            
            if isempty(jsonFiles)
                warning('appFramework:projection:NoMapsFound', ...
                    'No JSON files found in folder: %s', folderPath);
                return;
            end
            
            for i = 1:numel(jsonFiles)
                jsonFilePath = fullfile(jsonFiles(i).folder, jsonFiles(i).name);
                
                if endsWith(jsonFiles(i).name, '-schema.json')
                    continue;
                end
                
                try
                    projMap = appFramework.projection.ProjectionMap(jsonFilePath, obj);
                    obj.Maps{projMap.MATLABClass} = projMap;
                catch ME
                    warning('appFramework:projection:LoadError', ...
                        'Failed to load projection map %s: %s', ...
                        jsonFiles(i).name, ME.message);
                end
            end
        end
    end
    
    methods
        function projMap = getMap(obj, matlabClassName)
            % getMap - Get the ProjectionMap for a MATLAB class
            %
            % Inputs:
            %   matlabClassName - Fully qualified MATLAB class name
            %
            % Returns:
            %   projMap - ProjectionMap object
            %
            % Throws error if no map exists for the class
            
            arguments
                obj
                matlabClassName (1,1) string
            end
            
            if ~isKey(obj.Maps, matlabClassName)
                error('appFramework:projection:MapNotFound', ...
                    'No projection map found for class: %s', matlabClassName);
            end
            
            projMap = obj.Maps{matlabClassName};
        end
        
        function tf = hasMap(obj, matlabClassName)
            % hasMap - Check if a projection map exists for a class
            %
            % Inputs:
            %   matlabClassName - Fully qualified MATLAB class name
            %
            % Returns:
            %   tf - True if map exists
            
            arguments
                obj
                matlabClassName (1,1) string
            end
            
            tf = isKey(obj.Maps, matlabClassName);
        end
        
        function result = toJSON(obj, sourceObj, propertySubset)
            % toJSON - Convert a MATLAB object to a JSON-compatible struct
            %
            % Syntax:
            %   jsonStruct = engine.toJSON(obj)
            %   jsonStruct = engine.toJSON(obj, propertySubset)
            %
            % Inputs:
            %   sourceObj - MATLAB object to convert
            %   propertySubset - (Optional) String array of property names to include
            %
            % Returns:
            %   result - Struct suitable for jsonencode()
            
            arguments
                obj
                sourceObj
                propertySubset string = string.empty
            end
            
            className = class(sourceObj);
            
            if ~obj.hasMap(className)
                error('appFramework:projection:MapNotFound', ...
                    'No projection map found for class: %s', className);
            end
            
            projMap = obj.getMap(className);
            result = obj.projectObject(sourceObj, projMap, propertySubset);
        end
    end
    
    methods (Access = private)
        
        function result = projectObject(obj, sourceObj, projMap, propertySubset)
            % projectObject - Project a single object using a projection map
            
            result = struct();
            
            if isempty(propertySubset)
                propNames = projMap.getPropertyNames();
            else
                propNames = propertySubset;
                for i = 1:numel(propNames)
                    if ~projMap.hasProperty(propNames(i))
                        error('appFramework:projection:InvalidPropertySubset', ...
                            'Property "%s" not in projection map for %s', ...
                            propNames(i), projMap.MATLABClass);
                    end
                end
            end
            
            for i = 1:numel(propNames)
                propName = propNames(i);
                propDef = projMap.getPropertyDefinition(propName);
                
                if ~isprop(sourceObj, propName)
                    error('appFramework:projection:MissingProperty', ...
                        'Property "%s" not found on object of class %s', ...
                        propName, class(sourceObj));
                end
                
                propValue = sourceObj.(propName);
                
                projectedValue = obj.projectProperty(propValue, propDef, projMap);
                
                result.(propName) = projectedValue;
            end
        end
        
        function result = projectProperty(obj, value, propDef, projMap)
            % projectProperty - Project a single property value
            
            if isempty(value)
                if propDef.IsArray
                    result = [];
                else
                    result = [];
                end
                return;
            end
            
            if propDef.isPrimitive()
                result = value;
                return;
            end
            
            if propDef.IsReference
                result = obj.projectReference(value, propDef, projMap);
            else
                result = obj.projectNestedObject(value, propDef, projMap);
            end
        end
        
        function result = projectReference(obj, value, propDef, projMap)
            % projectReference - Project a reference property (only reference IDs)
            
            if ~projMap.hasNestedMap(propDef.Type)
                error('appFramework:projection:NestedMapNotFound', ...
                    'No nested map for type "%s"', propDef.Type);
            end
            
            nestedMap = projMap.getNestedMap(propDef.Type);
            refIdProps = nestedMap.ReferenceIDProperty;
            
            if isempty(refIdProps)
                error('appFramework:projection:NoReferenceIDProperty', ...
                    'Type "%s" has no ReferenceIDProperty defined', propDef.Type);
            end
            
            if propDef.IsArray
                if isempty(value)
                    result = [];
                    return;
                end
                
                numItems = numel(value);
                resultCell = cell(1, numItems);
                
                for i = 1:numItems
                    item = value(i);
                    refStruct = struct();
                    for j = 1:numel(refIdProps)
                        refPropName = refIdProps(j);
                        if ~isprop(item, refPropName)
                            error('appFramework:projection:MissingProperty', ...
                                'Reference ID property "%s" not found on object', refPropName);
                        end
                        refStruct.(refPropName) = item.(refPropName);
                    end
                    resultCell{i} = refStruct;
                end
                
                result = [resultCell{:}];
                if isempty(result)
                    result = [];
                end
            else
                refStruct = struct();
                for j = 1:numel(refIdProps)
                    refPropName = refIdProps(j);
                    if ~isprop(value, refPropName)
                        error('appFramework:projection:MissingProperty', ...
                            'Reference ID property "%s" not found on object', refPropName);
                    end
                    refStruct.(refPropName) = value.(refPropName);
                end
                result = refStruct;
            end
        end
        
        function result = projectNestedObject(obj, value, propDef, projMap)
            % projectNestedObject - Project a nested object (full projection)
            
            if ~projMap.hasNestedMap(propDef.Type)
                error('appFramework:projection:NestedMapNotFound', ...
                    'No nested map for type "%s"', propDef.Type);
            end
            
            nestedMap = projMap.getNestedMap(propDef.Type);
            
            if propDef.IsArray
                if isempty(value)
                    result = [];
                    return;
                end
                
                numItems = numel(value);
                resultCell = cell(1, numItems);
                
                for i = 1:numItems
                    item = value(i);
                    resultCell{i} = obj.projectObject(item, nestedMap, string.empty);
                end
                
                result = [resultCell{:}];
                if isempty(result)
                    result = [];
                end
            else
                result = obj.projectObject(value, nestedMap, string.empty);
            end
        end
    end
end
