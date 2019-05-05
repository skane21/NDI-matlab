function ndi_probetype2objectinit
% NDI_PROBETYPE2OBJECTINIT - Initializes the NDI_PROBETYPE2OBJECT global variable in NDI package
%
% NDI_PROBETYPE2OBJECTINIT
%
% Initializes the NDI_PROBETYPE2OBJECT structure. The structure has two fields,
% 'type' and 'classname'. Each entry describes the NDI_PROBE subclass to use to
% create an NDI_PROBE object for the given NDI_EPOCHCONTENTS_IODEVICE type.
% 
% Use TYPE NDI_PROBETYPE2OBJECTINIT to see the structure

ndi_globals

j = textfile2char([ndicommonpath filesep 'probe' filesep 'ndi_probetype2object.json']);

ndi_probetype2object = jsondecode(j);

