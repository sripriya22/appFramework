classdef (Abstract) AbstractController < handle
    % AbstractController - Base class for application controllers
    %
    % This abstract class provides the foundation for controllers that manage
    % communication between a MATLAB model and a JavaScript UI via uihtml.
    % Each concrete controller must implement getProjectionMapsPath() to
    % specify where its projection map JSON files are located.
    %
    % The controller:
    %   - Manages a ProjectionEngine for model-to-JSON conversion
    %   - Holds a root object that must be a type defined in projection maps
    %   - Provides invoke() for method calls on objects within the model
    %   - Dispatches events to/from the UI
    %   - Supports standalone testing mode when no uihtml is connected
    %
    % Method Invocation Pattern:
    %   result = ctrl.invoke(objectPath, methodName, args)
    %   - objectPath: Path to target object ("" for root, "Children[1]" for nested)
    %   - methodName: Any method on the target object
    %   - args: Cell array of arguments to pass to the method
    %
    % Example (concrete implementation):
    %   classdef MyAppController < appFramework.AbstractController
    %       methods (Access = protected)
    %           function path = getProjectionMapsPath(obj)
    %               path = fullfile(fileparts(mfilename('fullpath')), ...
    %                   '..', 'shared', 'model-projection');
    %           end
    %       end
    %   end
    %
    % See also: appFramework.utils.ModelPath
    
    properties (SetAccess = protected)
        ProjectionEngine
    end
    
    properties (SetAccess = protected)
        RootObject {mustBeScalarOrEmpty} = [] % must be a handle class if not empty
        RootClassName (1,1) string = ""
    end
    
    properties (Access = protected)
        HTMLComponent matlab.ui.control.HTML {mustBeScalarOrEmpty} = matlab.ui.control.HTML.empty
        EventLog (:,1) cell = {} % use if no HTMLComponent is registered
    end
    
    properties (Constant)
        Debug (1,1) logical = false
    end
    
    methods (Abstract, Access = protected)
        % getProjectionMapsPath - Return path to projection map JSON files
        %
        % Each concrete controller must implement this method to specify
        % the folder containing its projection map JSON files.
        %
        % Returns:
        %   path - Absolute path to the projection maps folder
        path = getProjectionMapsPath(obj)
    end
    
    methods (Access = protected)
        function obj = AbstractController(htmlComponent)
            % AbstractController - Construct controller with optional uihtml
            %
            % Syntax:
            %   ctrl = MyController()           % Standalone testing mode
            %   ctrl = MyController(htmlComp)   % Connected to UI
            %
            % Inputs:
            %   htmlComponent - (Optional) uihtml component for UI communication
            
            arguments
                htmlComponent matlab.ui.control.HTML {mustBeScalarOrEmpty} = matlab.ui.control.HTML.empty
            end
            
            mapsPath = obj.getProjectionMapsPath();
            obj.ProjectionEngine = appFramework.projection.ProjectionEngine(mapsPath);
            
            obj.HTMLComponent = htmlComponent;
            if ~isempty(htmlComponent)
                obj.HTMLComponent.HTMLEventReceivedFcn = @(src, evt) obj.handleEvent(evt);
            end
            
            obj.EventLog = {};
        end
        
        function result = invoke(obj, objectPath, methodName, args)
            % invoke - Call a method on an object within the model
            %
            % This is the primary way to interact with objects in the model.
            % First, the object at objectPath is resolved, then methodName
            % is called on it with the provided arguments.
            %
            % Inputs:
            %   objectPath - Path to target object ("" for root)
            %   methodName - Name of method to call on the target
            %   args       - Cell array of arguments for the method
            %
            % Returns:
            %   result - Return value from the method call (empty if void)
            %
            % Examples:
            %   % Get a property value
            %   name = ctrl.invoke("Species[1]", "get", {"Name"})
            %
            %   % Set a property value
            %   ctrl.invoke("Species[1]", "set", {"Name", "NewName"})
            %
            %   % Call any method
            %   ctrl.invoke("Species[1]", "validate", {})
            %
            %   % Act on root object
            %   ctrl.invoke("", "reset", {})
            %
            % See also: appFramework.utils.ModelPath
            
            arguments
                obj
                objectPath (1,1) string
                methodName (1,1) string
                args (1,:) cell = {}
            end
            
            obj.validateRootObject();
            
            mp = appFramework.utils.ModelPath(objectPath);
            targetObj = mp.resolve(obj.RootObject);
            
            try
                result = targetObj.(methodName)(args{:});
            catch ME
                if strcmp(ME.identifier, 'MATLAB:noSuchMethodOrField')
                    error('appFramework:controller:MethodNotFound', ...
                        'Method "%s" not found on object at path "%s"', ...
                        methodName, objectPath);
                end
                rethrow(ME);
            end
        end
        
        function result = toJSON(obj, propertySubset)
            % toJSON - Convert root object to JSON-compatible struct
            %
            % Syntax:
            %   jsonStruct = ctrl.toJSON()
            %   jsonStruct = ctrl.toJSON(["Name", "Value"])
            %
            % Inputs:
            %   propertySubset - (Optional) String array of properties to include
            %
            % Returns:
            %   result - Struct suitable for jsonencode()
            
            arguments
                obj
                propertySubset string = string.empty
            end
            
            obj.validateRootObject();
            result = obj.ProjectionEngine.toJSON(obj.RootObject, propertySubset);
        end
        
        function notifyUI(obj, eventName, data)
            % notifyUI - Send an event to the UI
            %
            % If connected to a uihtml component, sends via sendEventToHTMLSource.
            % Otherwise, logs the event for testing purposes.
            %
            % Inputs:
            %   eventName - Name of the event (string)
            %   data - Event payload (will be JSON-encoded)
            
            arguments
                obj
                eventName (1,1) string
                data = struct()
            end
            
            if obj.Debug
                disp("[Controller] Sending event: " + eventName);
            end
            
            if ~isempty(obj.HTMLComponent) && isvalid(obj.HTMLComponent)
                sendEventToHTMLSource(obj.HTMLComponent, eventName, data);
            else
                obj.EventLog{end+1} = struct('EventName', eventName, 'Data', data, ...
                    'Timestamp', datetime('now'));
            end
        end
        
        function handleEvent(obj, event)
            % handleEvent - Handle events from the UI
            %
            % Events from the UI should have:
            %   event.EventName - Name of the event (string)
            %   event.Data - Event payload (struct)
            %
            % Events are dispatched to methods named "on<EventName>"
            % e.g., event "UpdateParameter" calls onUpdateParameter(data)
            
            arguments
                obj
                event
            end
            
            if obj.Debug
                disp("[Controller] Received event: " + event.EventName);
            end
            
            methodName = "on" + event.EventName;
            
            if ismethod(obj, methodName)
                try
                    obj.(methodName)(event.Data);
                catch ME
                    obj.notifyUI("Error", struct('message', ME.message, 'event', event.EventName));
                    rethrow(ME);
                end
            else
                warning('appFramework:controller:UnhandledEvent', ...
                    'No handler method "%s" for event "%s"', methodName, event.EventName);
            end
        end
    end
    
    methods (Access = private)
        function log = getEventLog(obj)
            % getEventLog - Get logged events (for standalone testing)
            %
            % Returns:
            %   log - Cell array of event structs with EventName, Data, Timestamp
            
            log = obj.EventLog;
        end
        
        function clearEventLog(obj)
            % clearEventLog - Clear the event log
            
            obj.EventLog = {};
        end
        
        function tf = isConnected(obj)
            % isConnected - Check if controller is connected to a UI
            
            tf = ~isempty(obj.HTMLComponent) && isvalid(obj.HTMLComponent);
        end
    end
    
    methods (Access = protected)
        function setRootObject(obj, rootObj)
            % setRootObject - Set the root model object
            %
            % The object's class must have a corresponding projection map
            % loaded in the engine.
            %
            % Inputs:
            %   rootObj - MATLAB object to use as root model
            %
            % Throws error if no projection map exists for the object's class
            
            arguments
                obj
                rootObj
            end
            
            className = string(class(rootObj));
            
            if ~obj.ProjectionEngine.hasMap(className)
                error('appFramework:controller:UnknownRootClass', ...
                    'No projection map found for class: %s. Root object must be a type defined in projection maps.', ...
                    className);
            end
            
            obj.RootObject = rootObj;
            obj.RootClassName = className;
        end
        
        function resetRootObject(obj)
            % resetRootObject - Clear the root model object
            
            obj.RootObject = [];
            obj.RootClassName = "";
        end
        
        function validateRootObject(obj)
            % validateRootObject - Ensure root object is set
            
            if isempty(obj.RootObject)
                error('appFramework:controller:NoRootObject', ...
                    'Root object not set. Call setRootObject first.');
            end
        end
        
        function targetObj = resolveObject(obj, objectPath)
            % resolveObject - Get a reference to an object within the model
            %
            % Inputs:
            %   objectPath - Path to target object ("" for root)
            %
            % Returns:
            %   targetObj - The object at the specified path
            
            arguments
                obj
                objectPath (1,1) string
            end
            
            obj.validateRootObject();
            
            mp = appFramework.utils.ModelPath(objectPath);
            targetObj = mp.resolve(obj.RootObject);
        end
        
        function tf = hasRootObject(obj)
            % hasRootObject - Check if a root object is set
            
            tf = ~isempty(obj.RootObject);
        end
    end
end
