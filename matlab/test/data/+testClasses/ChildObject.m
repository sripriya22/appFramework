classdef ChildObject < handle
    % ChildObject - Test class representing a child/nested object
    
    properties
        SessionID (1,1) double = 0
        Name (1,1) string = ""
        Value (1,1) double = 0
        Units (1,1) string = ""
    end
    
    methods
        function obj = ChildObject(sessionID, name, value, units)
            arguments
                sessionID (1,1) double = 0
                name (1,1) string = ""
                value (1,1) double = 0
                units (1,1) string = ""
            end
            obj.SessionID = sessionID;
            obj.Name = name;
            obj.Value = value;
            obj.Units = units;
        end
    end
end
