classdef MotorOrderKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = 0;
    head_position_hist = [];
    htm;
    RIR;
    HTMFocusKS;

    shm = 0;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = MotorOrderKS (htm, htmFocusKS)
	obj.htm = htm;
    obj.RIR = htm.RIR;
    obj.HTMFocusKS = htmFocusKS;
end
% === CONSTRUCTOR [END] === %

function moveHead (obj)
    % --- If no sound -> make the head turn to 0� (resting state)
    focus = obj.HTMFocusKS.focused_object;
    if focus == 0
        theta = -obj.head_position;

    % --- Line above to be deleted -> already handle in the MotorOrderKS
    elseif obj.isFocusedObjectPresent() %&& focus ~= 0   % --- move the head to 'theta'
        theta = getObject(obj.RIR, focus, 'theta');
        % --- TO BE PLACED IN OBJECTDETECTIONKS
        % --- It's not up to this KS to set a new property to the object (-> AUDIOLOCALIZATIONKS)
        setObject(obj.RIR, focus, 'theta', 0);
    else                                            % --- go back to resting position (O�)
        theta = -obj.head_position;
        original_theta = getObject(obj.htm, focus, 'theta_hist');
        setObject(obj.RIR, focus, 'theta', original_theta(1));
        obj.RIR.getEnv().objects{focus}.theta_hist(end+1) = original_theta(1);
    end
    obj.head_position = mod(theta+obj.head_position, 360) ;
    obj.head_position_hist(end+1) = obj.head_position;

    obj.RIR.head_position = obj.head_position;

    obj.computeSHM();
end

function bool = isFocusedObjectPresent (obj)
    focus = obj.HTMFocusKS.focused_object;

    if obj.RIR.nb_objects == 0
        bool = false;
    elseif getObject(obj.RIR, focus, 'presence')
        bool = true;
    else
        bool = false;
    end
end

function computeSHM (obj)
    if numel(obj.head_position_hist) > 1
        if obj.head_position_hist(end-1) ~= obj.head_position_hist(end)
            obj.shm = obj.shm+1;
        end
    end
end

end
% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %