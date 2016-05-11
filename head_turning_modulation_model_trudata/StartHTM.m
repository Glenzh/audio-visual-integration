%warning('off', 'all');
disp( 'Initializing Two!Ears, setting up binaural simulator...' );

% ================= %
% === HTM MODIF === %
% ================= %

addpath(genpath('~/AuditoryModel/TwoEars_1.2'));
addpath(genpath('~/openrobots/lib/matlab'));

client = genomix.client('jido-base:8080') ;
bass = client.load('bass') ;
basc2 = client.load('basc2') ;
connection = basc2.connect_port('Audio', 'bass/Audio');

if (~strcmp(connection.status,'done'))
    error(connection.exception.ex);
end

% === Initialize Two!Ears model and check dependencies
startTwoEars();

% QR2matlab = client.load('QR2matlab') ;
% QR2matlab.connect_port('dataIn', '/visp_auto_tracker/code_message') ;

robot = Robot() ;
robot.initializeBass(bass, basc2) ;


% ================= %
% === HTM MODIF === %
% ================= %

% === Initialise and run model
disp( 'Building blackboard system...' );

bbs = BlackboardSystem(0);
bbs.setRobotConnect(robot) ;
bbs.setDataConnect('AuditoryFrontEndKS');

folder = '../ClassifierData' ;
d = dir(fullfile(folder, 'T*')) ;
nb_files = numel(d) ;
auditoryClassifiersKS = cell(0) ;
model_name = cell(1, numel(d)) ;

for iFile = 1:nb_files
	model = dir(fullfile(folder, d(iFile).name, '*.mat')) ;
	model = model.name(1:strfind(model.name, '.')-1) ;
	auditoryClassifiersKS{iFile} = bbs.createKS('AuditoryIdentityKS', {model, d(iFile).name}) ;
	model_name{iFile} = model ;
end

signalLevelKS = bbs.createKS('SignalLevelKS') ;
visualIdentityKS = bbs.createKS('VisualIdentityKS', {bbs.robotConnect});

headTurningModulationKS = bbs.createKS('HeadTurningModulationKS', {bbs.robotConnect});

localizerKS = bbs.createKS('DnnLocationKS');

bbs.blackboardMonitor.bind({bbs.scheduler},...
               {bbs.dataConnect},...
               'replaceOld', 'AgendaEmpty');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
						   {localizerKS},...
						   'replaceOld');

bbs.blackboardMonitor.bind({bbs.dataConnect},...
						   {signalLevelKS},...
                           'replaceOld' );

bbs.blackboardMonitor.bind({signalLevelKS},...
						   {auditoryClassifiersKS{1}},...
                           'replaceOld' );

for iClassifier = 2:numel(auditoryClassifiersKS)
	bbs.blackboardMonitor.bind({auditoryClassifiersKS{iClassifier-1}},...
                           {auditoryClassifiersKS{iClassifier}},...
                           'replaceOld' );
end

bbs.blackboardMonitor.bind({auditoryClassifiersKS{end}},...
						   {headTurningModulationKS},...
						   'replaceOld' );

setappdata(0, 'audio_labels', model_name) ;
setappdata(0, 'visual_labels', {'door', 'person', 'siren'}) ;

disp( 'Starting blackboard system.' );

bbs.run();

