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
    %   - Dispatches UI events to handler methods on controller or model objects
    %   - Supports standalone testing mode when no uihtml is connected
    %
    % Event Dispatch Pattern:
    %   Events from the UI are dispatched via dispatch(event) where event contains:
    %     EventType  - Name of the event (required)
    %     ObjectPath - Path to target ("" = controller, path = model object)
    %     MethodName - Handler method name (optional, defaults to handle<EventType>)
    %     Args       - Struct of named arguments
    %
    % Example (concrete implementation):
    %   classdef MyAppController < appFramework.AbstractController
    %       methods (Access = protected)
    %           function path = getProjectionMapsPath(obj)
    %               path = fullfile(fileparts(mfilename('fullpath')), ...
    %                   '..', 'shared', 'model-projection');
    %           end
    %           function results = handleLoadFile(obj, inputs)
    %               arguments
    %                   obj
    %                   inputs.FilePath (1,1) string
    %               end
    %               % ... implementation ...
    %               results = struct('Success', true);
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
                obj.HTMLComponent.HTMLEventReceivedFcn = @(src, evt) obj.dispatch(evt);
            end
            
            obj.EventLog = {};
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
        
        function dispatch(obj, event)
            % dispatch - Dispatch UI events to handler methods
            %
            % Routes events from the UI to the appropriate handler method.
            % The target can be the controller itself or a model object.
            %
            % Event schema:
            %   event.EventType  - Name of the event (required)
            %   event.ObjectPath - Target path: "" = controller, path = model object
            %   event.MethodName - Handler method name (optional)
            %   event.Args       - Struct of named arguments (optional)
            %
            % Method resolution:
            %   If MethodName is not provided, defaults to handle<EventType>
            %
            % Response:
            %   On success: notifyUI("DispatchResponse", {EventType, Results})
            %   On error: notifyUI("DispatchError", {EventType, Error})
            
            arguments
                obj
                event (1,1) struct
            end
            
            eventType = string(event.EventType);
            objectPath = "";
            if isfield(event, 'ObjectPath')
                objectPath = string(event.ObjectPath);
            end
            methodName = "";
            if isfield(event, 'MethodName') && ~isempty(event.MethodName)
                methodName = string(event.MethodName);
            else
                methodName = "handle" + eventType;
            end
            args = struct();
            if isfield(event, 'Args')
                args = event.Args;
            end
            
            if obj.Debug
                disp("[Controller] Dispatch: " + eventType + " -> " + methodName);
            end
            
            if objectPath == ""
                targetObj = obj;
            else
                obj.validateRootObject();
                mp = appFramework.utils.ModelPath(objectPath);
                targetObj = mp.resolve(obj.RootObject);
            end
            
            if ~ismethod(targetObj, methodName)
                error('appFramework:controller:MethodNotFound', ...
                    'Method "%s" not found on target', methodName);
            end
            
            reply = struct('EventType', eventType);
            
            try
                argsCell = namedargs2cell(args);
                reply.Results = targetObj.(methodName)(argsCell{:});
                obj.notifyUI("DispatchResponse", reply);
            catch ME
                reply.Error = struct('id', ME.identifier, 'message', ME.message);
                obj.notifyUI("DispatchError", reply);
                rethrow(ME);
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
            % setRootObject - Set the root model object and notify UI
            %
            % The object's class must have a corresponding projection map
            % loaded in the engine. After setting, notifies UI with the
            % full JSON representation of the root object.
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
            
            obj.notifyUI("RootObjectChanged", obj.toJSON());
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
