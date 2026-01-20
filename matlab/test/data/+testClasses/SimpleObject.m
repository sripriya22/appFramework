classdef SimpleObject < handle
    % SimpleObject - Test class with simple primitive properties
    
    properties
        Name (1,1) string = ""
        Value (1,1) double = 0
        IsActive (1,1) logical = false
        SessionID (1,1) double = 0
    end
    
    methods
        function obj = SimpleObject(name, value, isActive, sessionID)
            arguments
                name (1,1) string = ""
                value (1,1) double = 0
                isActive (1,1) logical = false
                sessionID (1,1) double = 0
            end
            obj.Name = name;
            obj.Value = value;
            obj.IsActive = isActive;
            obj.SessionID = sessionID;
        end
    end
end
