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
        
        function onUpdateName(obj, data)
            % Handler for UpdateName events
            target = obj.resolveObject("");
            target.Name = data.value;
        end
        
        function onUpdateValue(obj, data)
            % Handler for UpdateValue events
            target = obj.resolveObject("");
            target.Value = data.value;
        end
        
        function onGetModel(obj, ~)
            % Handler for GetModel events - sends model to UI
            if obj.hasRootObject()
                jsonData = obj.toJSON();
                obj.notifyUI("ModelLoaded", jsonData);
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
        
        function result = testInvoke(obj, objectPath, methodName, args)
            % Public wrapper for testing - delegates to protected method
            arguments
                obj
                objectPath (1,1) string
                methodName (1,1) string
                args (1,:) cell = {}
            end
            result = obj.invoke(objectPath, methodName, args);
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
        
        function testHandleEvent(obj, event)
            % Public wrapper for testing - delegates to protected handleEvent
            obj.handleEvent(event);
        end
        
        function simulateEvent(obj, eventName, data)
            % Test helper - simulate receiving an event from UI
            % Uses the actual handleEvent method
            event = struct('EventName', eventName, 'Data', data);
            obj.handleEvent(event);
        end
    end
end
