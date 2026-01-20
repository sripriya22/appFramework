classdef TestController < appFramework.AbstractController
    % TestController - Concrete controller for testing AbstractController
    
    methods (Access = protected)
        function path = getProjectionMapsPath(obj) %#ok<MANU>
            % Return path to test data projection maps
            path = fullfile(fileparts(mfilename('fullpath')), '..', '..');
            path = fullfile(path, 'data');
        end
    end
    
    methods
        function obj = TestController(htmlComponent)
            % TestController - Construct test controller
            
            arguments
                htmlComponent matlab.ui.control.HTML {mustBeScalarOrEmpty} = matlab.ui.control.HTML.empty
            end
            
            obj@appFramework.AbstractController(htmlComponent);
        end
        
        function results = handleUpdateName(obj, inputs)
            % Handler for UpdateName - update root object name
            arguments
                obj
                inputs.Value (1,1) string
            end
            target = obj.resolveObject("");
            target.Name = inputs.Value;
            results = struct('Name', target.Name);
        end
        
        function results = handleUpdateValue(obj, inputs)
            % Handler for UpdateValue - update root object value
            arguments
                obj
                inputs.Value (1,1) double
            end
            target = obj.resolveObject("");
            target.Value = inputs.Value;
            results = struct('Value', target.Value);
        end
        
        function results = handleGetModel(obj)
            % Handler for GetModel - returns model JSON
            arguments
                obj
            end
            if obj.hasRootObject()
                results = struct('Model', obj.toJSON());
            else
                results = struct('Model', struct());
            end
        end
        
        function testSetRootObject(obj, rootObj)
            % Public wrapper for testing - delegates to protected method
            obj.setRootObject(rootObj);
        end
        
        function testResetRootObject(obj)
            % Public wrapper for testing - delegates to protected method
            obj.resetRootObject();
        end
        
        function result = testToJSON(obj, propertySubset)
            % Public wrapper for testing - delegates to protected method
            arguments
                obj
                propertySubset string = string.empty
            end
            result = obj.toJSON(propertySubset);
        end
        
        function testNotifyUI(obj, eventName, data)
            % Public wrapper for testing - delegates to protected method
            arguments
                obj
                eventName (1,1) string
                data = struct()
            end
            obj.notifyUI(eventName, data);
        end
        
        function tf = testHasRootObject(obj)
            % Public wrapper for testing
            tf = ~isempty(obj.RootObject);
        end
        
        function targetObj = testResolveObject(obj, objectPath)
            % Public wrapper for testing - delegates to protected resolveObject
            arguments
                obj
                objectPath (1,1) string
            end
            targetObj = obj.resolveObject(objectPath);
        end
        
        function log = testGetEventLog(obj)
            % Public wrapper for testing - get event log
            log = obj.EventLog;
        end
        
        function testClearEventLog(obj)
            % Public wrapper for testing - clear event log
            obj.EventLog = {};
        end
        
        function tf = testIsConnected(obj)
            % Public wrapper for testing - check if connected
            tf = ~isempty(obj.HTMLComponent) && isvalid(obj.HTMLComponent);
        end
        
        function testDispatch(obj, event)
            % Public wrapper for testing - delegates to protected dispatch
            obj.dispatch(event);
        end
        
        function simulateEvent(obj, eventType, args)
            % Test helper - simulate receiving an event from UI
            % Uses the actual dispatch method
            %
            % Inputs:
            %   eventType - Event type (handler will be handle<EventType>)
            %   args - Struct of named arguments for the handler
            arguments
                obj
                eventType (1,1) string
                args (1,1) struct = struct()
            end
            event = struct('EventType', eventType, 'Args', args);
            obj.dispatch(event);
        end
    end
end
