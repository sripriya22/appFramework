classdef ModelPath
    % ModelPath - Utility class for parsing and resolving object paths
    %
    % This class parses a model path string and provides methods to resolve
    % objects within an object graph. The path uses dot notation with optional
    % array indexing to navigate through nested objects.
    %
    % Path Format:
    %   ""                  - Root object (empty path)
    %   "PropertyName"      - Direct property of root
    %   "Property.Sub"      - Nested property access
    %   "Array[1]"          - Array element (1-indexed, must be > 0)
    %   "Array[1].Name"     - Property of array element
    %
    % Indexing:
    %   All indices are 1-based (MATLAB-native). Index values must be > 0.
    %   The JavaScript client is responsible for converting from 0-based
    %   indexing if needed.
    %
    % Future Enhancement:
    %   Support for referenceID-based lookup (e.g., "Children[#123]") is
    %   planned to allow identifying objects by their unique ID instead of
    %   array position.
    %
    % Example:
    %   mp = appFramework.utils.ModelPath("Species[1].Parameters[2]");
    %   targetObj = mp.resolve(rootObject);
    %   targetObj.Name = "NewName";  % Direct property access
    %
    % See also: appFramework.AbstractController
    
    properties (SetAccess = private)
        PathString (1,1) string
        Segments struct = struct('Property', {}, 'Index', {})
    end
    
    methods
        function obj = ModelPath(pathString)
            % ModelPath - Construct a ModelPath from a path string
            %
            % Inputs:
            %   pathString - String specifying the object path
            
            arguments
                pathString (1,1) string = ""
            end
            
            obj.PathString = pathString;
            obj.Segments = obj.parse(pathString);
        end
        
        function targetObj = resolve(obj, rootObject)
            % resolve - Navigate to the target object at this path
            %
            % Inputs:
            %   rootObject - The root object to start navigation from
            %
            % Returns:
            %   targetObj - The object at the specified path
            %
            % Throws error if path is invalid or object not found
            
            arguments
                obj
                rootObject
            end
            
            if isempty(obj.Segments)
                targetObj = rootObject;
                return;
            end
            
            currentObj = rootObject;
            
            for i = 1:numel(obj.Segments)
                seg = obj.Segments(i);
                
                if ~isprop(currentObj, seg.Property) && ~isfield(currentObj, seg.Property)
                    error('appFramework:utils:InvalidPath', ...
                        'Property "%s" not found at path segment %d of "%s"', ...
                        seg.Property, i, obj.PathString);
                end
                
                if seg.Index > 0
                    propValue = currentObj.(seg.Property);
                    if seg.Index > numel(propValue)
                        error('appFramework:utils:IndexOutOfBounds', ...
                            'Index %d exceeds array size %d for property "%s" in path "%s"', ...
                            seg.Index, numel(propValue), seg.Property, obj.PathString);
                    end
                    currentObj = propValue(seg.Index);
                else
                    currentObj = currentObj.(seg.Property);
                end
            end
            
            targetObj = currentObj;
        end
        
        function tf = isEmpty(obj)
            % isEmpty - Check if this is an empty path (refers to root)
            
            tf = isempty(obj.Segments);
        end
        
        function n = numSegments(obj)
            % numSegments - Get the number of path segments
            
            n = numel(obj.Segments);
        end
        
        function str = char(obj)
            % char - Convert to character array for display
            
            str = char(obj.PathString);
        end
        
        function str = string(obj)
            % string - Convert to string
            
            str = obj.PathString;
        end
    end
    
    methods (Access = private)
        function segments = parse(~, pathString)
            % parse - Parse a path string into segments
            %
            % Each segment has:
            %   Property - The property name (string)
            %   Index    - Array index (0 if not indexed)
            
            if pathString == ""
                segments = struct('Property', {}, 'Index', {});
                return;
            end
            
            parts = split(pathString, ".");
            segments = struct('Property', {}, 'Index', {});
            
            for i = 1:numel(parts)
                part = parts(i);
                
                bracketMatch = regexp(part, '^(\w+)\[(\d+)\]$', 'tokens');
                
                if ~isempty(bracketMatch)
                    segments(i).Property = string(bracketMatch{1}{1});
                    idx = str2double(bracketMatch{1}{2});
                    if idx < 1
                        error('appFramework:utils:InvalidIndex', ...
                            'Index must be >= 1 (1-based indexing). Got %d in path segment "%s"', ...
                            idx, part);
                    end
                    segments(i).Index = idx;
                else
                    if ~isempty(regexp(part, '\[|\]', 'once'))
                        error('appFramework:utils:InvalidPathSyntax', ...
                            'Invalid bracket syntax in path segment "%s"', part);
                    end
                    segments(i).Property = part;
                    segments(i).Index = 0;
                end
            end
        end
    end
    
    methods (Static)
        function validatePathString(pathString)
            % validatePathString - Validate path string syntax without parsing
            %
            % Throws error if syntax is invalid
            
            arguments
                pathString (1,1) string
            end
            
            if pathString == ""
                return;
            end
            
            % Check for valid characters
            if ~isempty(regexp(pathString, '[^\w\.\[\]]', 'once'))
                error('appFramework:utils:InvalidPathCharacters', ...
                    'Path contains invalid characters: "%s"', pathString);
            end
            
            % Check bracket matching
            openCount = count(pathString, "[");
            closeCount = count(pathString, "]");
            if openCount ~= closeCount
                error('appFramework:utils:UnmatchedBrackets', ...
                    'Unmatched brackets in path: "%s"', pathString);
            end
        end
    end
end
