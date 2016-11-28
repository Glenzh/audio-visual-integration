% 'ObjectDetectionKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef ObjectDetectionKS < handle

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	htm; % Head_Turning_Modulation KS
	RIR; % Robot_Internal_Representation KS
	
	create_new = cell(0);
	update_object = cell(0);
	id_object = cell(0);
end

properties (SetAccess = private, GetAccess = private)
	thr_theta;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = ObjectDetectionKS (htm)
	obj.htm = htm;
	obj.RIR = htm.RIR;
	obj.thr_theta = getInfo('thr_theta');
end
% === CONSTRUCTOR [END] === %

function execute (obj)
    % hyp = zeros(getInfo('nb_sources'), 3);
	
% 	theta_a = getLastHypothesis(obj, 'ALKS');
% 	theta_v = getLastHypothesis(obj, 'VLKS');
%     if sum(theta_a) == 0 || sum(theta_v) == 0
%         hyp = [0, 0, 0];
%         obj.setHypotheses(hyp);
%         return;
%     end

    % [Ba, Ia] = sort(theta_a, 'descend');
    % [Bv, Iv] = sort(theta_v, 'descend');
    % f = intersect(Ia(1:5), Iv(1:5));

    % if isempty(f)
    % 	hyp = [0, 0, 0];
    % 	obj.setHypotheses(hyp)
    % 	return;
    % end
    hyp_ssks = getLastHypothesis(obj, 'SSKS');
    nb_streams = numel(hyp_ssks.current_streams);
    
    nb_objects = obj.RIR.nb_objects;
    hyp = zeros(nb_streams, 3);
    for iStream = 1:nb_streams
    	iSource = hyp_ssks.current_streams(iStream);
    	putative_audio_object = [];
    	if hyp_ssks.azimuths(1, iStream) == hyp_ssks.azimuths(2, iStream)
	    	for iObject = 1:obj.RIR.nb_objects
	    		theta_o = getObject(obj, iObject, 'theta');
	            theta_o = theta_o(end);
	    		theta_diff_a = theta_o - hyp_ssks.azimuths(1, iSource);
		    	if theta_diff_a <= obj.thr_theta  && theta_diff_a >= -obj.thr_theta
		    		putative_audio_object(end+1) = iObject;
		    	end
		    end
		end
	    if isempty(putative_audio_object) % --- Create a new object
			hyp(iStream, :) = [1, 0, nb_objects+1];
			nb_objects = nb_objects+1;
		else % --- Update already existing object
			hyp(iStream, :) = [0, 1, putative_audio_object(1)];
		end
	end
	obj.setHypotheses(hyp);
end

function setHypotheses (obj, hyp)
	obj.create_new{end+1} = hyp(:, 1);
	obj.update_object{end+1} = hyp(:, 2);
	obj.id_object{end+1} = hyp(:, 3);
end

function plotDecisions (obj)
	figure;
	hold all;
	line(1:getInfo('nb_steps'), obj.create_new, 'Marker', '*', 'LineStyle', 'none', 'Color', 'r', 'MarkerSize', 16);
	line(1:getInfo('nb_steps'), obj.update_object, 'Marker', 'o', 'LineStyle', 'none', 'MarkerSize', 16);
	plot(1:getInfo('nb_steps'), obj.id_object, 'LineWidth', 2, 'LineStyle', '-');
	legend({'Create', 'Update', 'ID'}, 'FontSize', 12);
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end