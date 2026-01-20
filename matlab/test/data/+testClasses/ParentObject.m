classdef ParentObject < handle
    % ParentObject - Test class with nested objects and references
    
    properties
        SessionID (1,1) double = 0
        Name (1,1) string = ""
        Children (:,1) testClasses.ChildObject = testClasses.ChildObject.empty(0,1)
        SelectedChildren (:,1) testClasses.ChildObject = testClasses.ChildObject.empty(0,1)
        StartTime (1,1) double = 0
        StopTime (1,1) double = 100
    end
    
    methods
        function obj = ParentObject(sessionID, name)
            arguments
                sessionID (1,1) double = 0
                name (1,1) string = ""
            end
            obj.SessionID = sessionID;
            obj.Name = name;
        end
        
        function addChild(obj, child)
            arguments
                obj
                child (1,1) testClasses.ChildObject
            end
            obj.Children(end+1) = child;
        end
        
        function selectChild(obj, child)
            arguments
                obj
                child (1,1) testClasses.ChildObject
            end
            obj.SelectedChildren(end+1) = child;
        end
    end
end
