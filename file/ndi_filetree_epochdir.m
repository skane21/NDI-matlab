% NDI_FILETREE_EPOCHDIR - Create a new NDI_FILETREE_EPOCHDIR object
%
%  DT = FILETREE_EPOCHDIR(EXP, FILETYPE)   
%
%  Creates a new file tree object with the experiment name 
%  This class in inhereted from filetree and with epochdir organization
%

classdef ndi_filetree_epochdir < ndi_filetree
	properties
	end

	methods

		function obj = ndi_filetree_epochdir(varargin)
		% NDI_FILETREE_EPOCHDIR - Create a new NDI_FILETREE_EPOCHDIR object that is associated with an experiment and device
		%
		%   OBJ = NDI_FILETREE_EPOCHDIR(EXP, [FILEPARAMETERS, EPOCHCONTENTS_CLASS, EPOCHCONTENTS_FILEPARAMETERS])
		%
		% Creates a new NDI_FILETREE_EPOCHDIR object that negotiates the data tree of device's data that is
		% stored in an experiment EXP.
		%
		% (document FILEPARAMETERS)
		%
		% Inputs: EXP - an NDI_EXPERIMENT ; FILEPARAMETERS - the files that are recorded in each epoch
		%      FILEPARAMETERS: the files that are recorded in each epoch of DEVICE in this
		%          data tree style (see NDI_FILETREE/SETFILEPARAMETERS for description)
		%      EPOCHCONTENTS_CLASS: the class of epoch_record to be used; 'ndi_epochcontents_iodevice' is used by default
		%      EPOCHCONTENTS_FILEPARAMETERS: the file parameters to search for the epoch record file among the files
		%          present in each epoch (see NDI_FILETREE/SETEPOCHCONTENTSFILEPARAMETERS). By default, the file location
		%          specified in NDI_FILETREE/EPOCHCONTENTSFILENAME is used
		%
		% Output: OBJ - an NDI_FILETREE_EPOCHDIR object
		%
		% See also: NDI_EXPERIMENT, NDI_IODEVICE
		%
			obj = obj@ndi_filetree(varargin{:});
		end

		% in NDI_BASE, need to change epochcontentsfilename to defaultepochcontentsfilename

		%% methods overriding NDI_BASE

			function [obj,properties_set] = setproperties(ndi_filetree_obj, properties, values)
			% SETPROPERTIES - set the properties of an NDI_FILETREE object
			%
			% [OBJ,PROPERTIESSET] = SETPROPERTIES(NDI_FILETREE_OBJ, PROPERTIES, VALUES)
			%
			% Given a cell array of string PROPERTIES and a cell array of the corresponding
			% VALUES, sets the fields in NDI_FILETREE_OBJ and returns the result in OBJ.
			%
			% If any entries in PROPERTIES are not properties of NDI_FILETREE_OBJ, then
			% that property is skipped.
			%
			% The properties that are actually set are returned in PROPERTIESSET.
			%
			% Developer note: when creating a subclass of NDI_FILETREE that has its own properties that
			% need to be read/written from disk, copy this method SETPROPERTIES into the new class so that
			% you will be able to set all properties (this instance can only set properties of NDI_FILETREE).
			%
				fn = fieldnames(ndi_filetree_obj);
				obj = ndi_filetree_obj;
				properties_set = {};
				for i=1:numel(properties),
					if any(strcmp(properties{i},fn)) | any (strcmp(properties{i}(2:end),fn)),
						if properties{i}(1)~='$',
							eval(['obj.' properties{i} '= values{i};']);
							properties_set{end+1} = properties{i};
						else,
							switch properties{i}(2:end),
								case 'fileparameters',
									if ~isempty(values{i}),
										fp = eval(values{i});
										obj = obj.setfileparameters(fp);
									else,
										obj.fileparameters = [];
									end;
								case 'epochcontents_fileparameters',
									if ~isempty(values{i}),
										fp = eval(values{i});
										obj = obj.setepochcontentsfileparameters(fp);
									else,
										obj.epochcontents_fileparameters = [];
									end
							otherwise,
								error(['Do not know how to set property ' properties{i}(2:end) '.']);
							end
							properties_set{end+1} = properties{i}(2:end);
						end
					end
				end
		end % setproperties()

		%% methods overriding NDI_EPOCHSET

		function id = epochid(ndi_filetree_epochdir_obj, epoch_number, epochfiles)
		% EPOCHID = Get the epoch identifier for a particular epoch
		%
		% ID = EPOCHID(NDI_FILETREE_EPOCHDIR_OBJ, EPOCH_NUMBER, [EPOCHFILES])
		%
		% Returns the epoch identifier string for the epoch EPOCH_NUMBER.
		% For the NDI_FILETREE_EPOCHDIR object, each EPOCH is organized in its own subdirectory,
		% and the epoch identifier is the _name_ of the subdirectory.
		%
		% For example, if my device has a file tree that reads files with extension .dat,
		% the experiment directory is
		%
		% myexperiment/
		%       t00001/
		%          mydata.dat
		%
		% Then ID is 't00001'
		%
			if nargin < 3,
				epochfiles = getepochfiles(ndi_filetree_epochdir_obj, epoch_number);
			end
			[pathdir,filename] = fileparts(epochfiles{1});
			[abovepath, id] = fileparts(pathdir);
		end % epochid

		%% methods overriding NDI_FILETREE
	
		function [epochfiles] = selectfilegroups(ndi_filetree_epochdir_obj)
			% SELECTFILEGROUPS - Return groups of files that will comprise epochs
			%
			% EPOCHFILES = SELECTFILEGROUPS(NDI_FILETREE_EPOCHDIR_OBJ)
			%
			% Return the files that comprise epochs.
			%
			% EPOCHFILES{n} will be a cell list of the files in epoch n.
			%
			% For NDI_FILETREE_EPOCHDIR, this uses the file matching parameters in all
			% subdirectories within the experiment (at a folder depth of 1; that is, it doesn't
			% search folders in folders).
			%
			% See also: NDI_FILETREE/SETFILEPARAMETERS
			%
				exp_path = ndi_filetree_epochdir_obj.path();
				epochfiles = findfilegroups(exp_path, ndi_filetree_epochdir_obj.fileparameters.filematch,...
					'SearchParent',0,'SearchDepth',1);
		end % selectfilegroups

	end % methods
end
