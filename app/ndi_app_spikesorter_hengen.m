classdef ndi_app_spikesorter_hengen < ndi_app

	properties (SetAccess=protected,GetAccess=public)
	end % properties

	methods

		function ndi_app_spikesorter_hengen_obj = ndi_app_spikesorter_hengen(varargin)
		% NDI_APP_spikesorter_hengen - an app to sort spikewaves found in experiments using hengen Spike Sorter
		%
		% NDI_APP_spikesorter_hengen_OBJ = NDI_APP_spikesorter_hengen(EXPERIMENT)
		%
		% Creates a new NDI_APP_spikesorter_hengen object that can operate on
		% NDI_EXPERIMENTS. The app is named 'ndi_app_spikesorter_hengen'.
		%
			experiment = [];
			name = 'ndi_app_spikesorter_hengen';
			if numel(varargin)>0,
				experiment = varargin{1};
			end
			ndi_app_spikesorter_hengen_obj = ndi_app_spikesorter_hengen_obj@ndi_app(experiment, name);

		end % ndi_app_spikesorter() creator

		function extract_and_sort(ndi_app_spikesorter_hengen_obj, redo)
		% EXTRACT_AND_SORT - extracts and sorts selected .bin file in ndi_experiment directory
		%
			
			if isempty(redo)
				redo = 0
			end
			
			warning([newline 'This app assumes macOS with python3.8 installed with homebrew' newline 'as well as the following packages:' newline ' numpy' newline ' scipy' newline ' ml_ms4alg' newline ' seaborn' newline ' neuraltoolkit' newline ' musclebeachtools' newline ' spikeinterface' newline '  ^ requires appropriate modification of source in line 611 of postprocessing_tools.py (refer to musclebeachtools FAQ)'])
			warning('Change line 66 in this app to point to appropriate python3.8 installation')
			prev_folder = cd(ndi_app_spikesorter_hengen_obj.experiment.path);

			% deal with directory clustering_output
			if isfolder('clustering_output')
				if redo == 1
					rmdir('clustering_output', 's')
					mkdir('clustering_output')
				elseif redo == 0
					error(['Folder clustering_output exists. Remove directory or make redo value 1 to overwrite'])
				else
					error(['redo should be either 0 or 1'])
				end
			else
				mkdir('clustering_output')
			end
			
			% delete existing tmp dir and create it
			if isfolder('tmp')
				rmdir('tmp', 's')
			end

			mkdir('tmp')

			cd(prev_folder);

			ndi_globals;

			ndi_hengen_path = [ndipath filesep 'app' filesep 'spikesorter_hengen'];

			prev_folder = cd(ndi_hengen_path);

			system(['/usr/local/opt/python@3.8/bin/python3 spikeinterface_currentall.py -f json_input_files/spkint_wrapper_input_64ch.json --experiment-path ' ndi_app_spikesorter_hengen_obj.experiment.path ' --ndi-hengen-path ' ndi_hengen_path])
			%python spikeinterface_currentall.py -f json_input_files/spkint_wrapper_input_64ch.json

			cd(prev_folder)
		end % extract_and_sort

		function rate_neuron_quality(ndi_app_spikesorter_hengen_obj)
		% RATE_NEURON_QUALITY - given an existing sorting output from hengen sorter, rate neuron quality and add ndi_things to experiment

			% TODO: remove temp code
			%%% temp %%%
			doc = ndi_app_spikesorter_hengen_obj.experiment.database_search({'ndi_document.type','ndi_thing(.*)'});
			if ~isempty(doc),
				for i=1:numel(doc),
					ndi_app_spikesorter_hengen_obj.experiment.database_rm(doc{i}.id());
				end;
			end;
			%%% temp %%%

			warning([newline 'This app assumes a UNIX machine with python3 installed' newline 'as well as the following packages:' newline 'numpy' newline ' scipy' newline ' neuraltoolkit' newline ' musclebeachtools' newline ' spikeinterface' newline '  ^ requires appropriate modification of source in line 611 of postprocessing_tools.py (refer to musclebeachtools FAQ)'])

			ndi_globals;

			prev_folder = cd([ndipath filesep 'app' filesep 'spikesorter_hengen']);

			% python spikeinterface_currentall.py -f json_input_files/spkint_wrapper_input_64ch.json
			warning(['using /usr/local/bin/python3' newline 'modify source to use a different python installation'])
			system(['/usr/local/bin/python3 rate_neuron_quality.py --experiment-path '  ndi_app_spikesorter_hengen_obj.experiment.path])

			load('tmp.mat', 'n');

			for i=1:2 % TODO: hardcoded
				neuron = n{i}

				neuron_thing_doc = ndi_app_spikesorter_hengen_obj.experiment.newdocument('apps/spikesorter_hengen/neuron_hengen', ...
					...% thing properties
					'thing.name', ['neuron_' num2str(neuron.clust_idx+1)],...
					'thing.reference', num2str(neuron.clust_idx),...
					'thing.type', 'neuron',...
					'thing.direct', 0,...
					...% neuron_hengen_object properties (from musclebeachtools)
					'neuron_properties.waveform', neuron.waveform,...
					'neuron_properties.waveforms', neuron.waveforms,...
					'neuron_properties.clust_idx', neuron.clust_idx,...
					'neuron_properties.quality', neuron.quality,...
					'neuron_properties.cell_type', neuron.cell_type,...
					'neuron_properties.mean_amplitude', neuron.mean_amplitude,...
					'neuron_properties.waveform_tetrodes', neuron.waveform_tetrodes,...
					'neuron_properties.spike_amplitude', neuron.spike_amplitude...
				) + ndi_app_spikesorter_hengen_obj.newdocument()

				neuron_thing_doc.set_dependency_value('underlying_thing_id', ''); % TODO: is this the right way of doing this?

				ndi_app_spikesorter_hengen_obj.experiment.database_add(neuron_thing_doc);

				neuron_thing = ndi_thing_timeseries(ndi_app_spikesorter_hengen_obj.experiment, neuron_thing_doc.id);

				[neuron_thing, neuron_thing_doc] = neuron_thing.addepoch('epoch1', ndi_clocktype('dev_local_time'), [neuron.on_times, neuron.off_times], [neuron.spike_time / neuron.fs]', ones(numel(neuron.spike_time), 1));
				
				% Test plotting
				% [d,t] = readtimeseries(neuron_thing, 1, -Inf, Inf);
				% figure;
				% plot(t, d, 'o');
			end

			delete tmp.mat

			cd(prev_folder)

		end % rate_neuron_quality

		
		% function spike_sort(ndi_app_spikesorter_obj, ndi_timeseries_obj, epoch, extraction_name, sort_name, redo)
		% % SPIKE_SORT - method that sorts spikes from specific probes in experiment to ndi_doc
		% %
		% % SPIKE_SORT(SPIKEWAVES, SORT_NAME, SORTING_PARAMS)
		% %%%%%%%%%%%%%%
		% % SORT_NAME name given to save sort to ndi_doc
			
		% 	if exist('redo') == 0
		% 		redo = 0
		% 	end

		% 	% epoch_string = ndi_timeseries_obj.epoch2str(epoch{n});

		% 	% sorter_searchq = cat(2,ndi_app_spikesorter_obj.searchquery(), ...
		% 	% 			{'epochid', epoch_string, 'spikewaves.sort_name', extraction_name});
		% 	% 		old_sort_doc = ndi_app_spikesorter_obj.experiment.database_search(spikewaves_searchq);
					
		% 	% if ~isempty(old_sort_doc) & ~redo
		% 	% 	% we already have this epoch
		% 	% 	continue % skip to next epoch
		% 	% end

		% 	% Clear sort within probe with sort_name
		% 	ndi_app_spikesorter_obj.clear_sort(ndi_timeseries_obj, epoch, sort_name);

		% 	sort_searchq = ndi_query('ndi_document.name','exact_string',sort_name,'') & ...
		% 			ndi_query('','isa','sorting_parameters','');
		% 			sorting_parameters_doc = ndi_app_spikesorter_obj.experiment.database_search(sort_searchq);
		% 	if isempty(sorting_parameters_doc),
		% 		error(['No sorting_parameters document named ' sort_name ' found.']);
		% 	elseif numel(sorting_parameters_doc)>1,
		% 		error(['More than one sorting_parameters document with same name. Should not happen but needs to be fixed.']);
		% 	else,
		% 		sorting_parameters_doc = sorting_parameters_doc{1};
		% 	end;

		% 	% Read spikewaves here
		% 	spike_extractor = ndi_app_spikeextractor(ndi_app_spikesorter_obj.experiment);
		% 	waveforms = spike_extractor.load_spikewaves_epoch(ndi_timeseries_obj, epoch, extraction_name);

		% 	% Interpolation
		% 	interpolation = sorting_parameters_doc.document_properties.sorting_parameters.interpolation;
		% 	waveforms_out = zeros(interpolation*size(waveforms,1), size(waveforms,2), size(waveforms,3));
		% 	x = 1:length(waveforms(:,1,1));
		% 	xq = 1/interpolation:1/interpolation:length(waveforms(:,1,1));
			
		% 	for i=1:size(waveforms, 3)
		% 		waveforms_out(:,:,i) = interp1(x, waveforms(:,:,i), xq, 'spline');
		% 	end

		% 	spikesamples = size(waveforms_out,1);
		% 	nchannels = size(waveforms_out,2);
		% 	nspikes = size(waveforms_out,3);
		% 	% Concatenate waves for PCA
		% 	concatenated_waves = reshape(waveforms_out,[spikesamples * nchannels,nspikes]);
		% 	concatenated_waves = concatenated_waves';
		% 	%% Spike Features (PCA)

		% 	% get covariance matrix of the TRANSPOSE of spike array (waveforms need
		% 	% to be in the rows for cov to give what we want)
		% 	covariance = cov(concatenated_waves);

		% 	% get eigenvectors & eigenvalues - these are pre-sorted in order of
		% 	% ASCENDING eigenvalue
		% 	[eigenvectors, eigenvalues] = eig(covariance);
		% 	eigvals = diag(eigenvalues);

		% 	% sort in order of DESCENDING eigenvalues
		% 	[eigvals, indx] = sort(eigvals, 'descend');
		% 	eigenvectors = eigenvectors(:, indx);

		% 	% Project original waveforms into eigenvector space
		% 	projected_waveforms = concatenated_waves * [eigenvectors];

		% 	% Features used in klustakwik_cluster
		% 	pca_coefficients = projected_waveforms(:, 1:sorting_parameters_doc.document_properties.sorting_parameters.num_pca_features);

		% 	disp('KlustarinKwikly...');
		% 	[clusterids,numclusters] = klustakwik_cluster(pca_coefficients, 3, 25, 5, 0);

		% 	% For spikewaves gui
		% 	% disp('Cluster_spikewaves_gui testing...')
		% 	% [~, ~, ~, ~, channellist_in_probe] = getchanneldevinfo(probe, 1);
		% 	% waveparameters = struct;
		% 	% waveparameters.numchannels = numel(channellist_in_probe);
		% 	% waveparameters.S0 = -9 * interpolation;
		% 	% waveparameters.S1 = 20 * interpolation;
		% 	% waveparameters.name = '';
		% 	% waveparameters.ref = 1;
		% 	% waveparameters.comment = '';
		% 	% waveparameters.samplingrate = probe.samplerate(1) * interpolation;% ;

		% 	% spikewaves = ndi_app_spikesorter_obj.load_spikewaves_epoch(ndi_timeseries_obj, epoch, extraction_name);
		% 	times = ndi_app_spikesorter_obj.load_spiketimes_epoch(ndi_timeseries_obj, epoch, extraction_name);
		% 	% spiketimes_samples = ndi_timeseries_obj.times2samples(1, times);
            
            
		% 	% Uncomment to enable spikewaves_gui
		% 	% cluster_spikewaves_gui('waves', spikewaves, 'waveparameters', waveparameters, 'clusterids', spikeclusterids, 'wavetimes', spiketimes);

		% 	% 'EpochStartSamples', epoch_start_samples, 'EpochNames', epoch_names);
		% 	disp('Done clustering.');
		% 	figure(101);
		% 	hist(clusterids);

		% 	% Create spike_clusters ndi_doc
		% 	spike_clusters_doc = ndi_app_spikesorter_obj.experiment.newdocument('apps/spikesorter/spike_clusters', ...
		% 		'spike_sort.sort_name', sort_name, ...
		% 		'spike_sort.sorting_parameters_file_id', sorting_parameters_doc.id, ...
		% 		'spike_sort.clusterids', clusterids, ...
		% 		'spike_sort.spiketimes', times, ...
		% 		'spike_sort.numclusters', numclusters) ...
		% 		+ ndi_timeseries_obj.newdocument() + ndi_app_spikesorter_obj.newdocument();

		% 	% Add doc to database
		% 	ndi_app_spikesorter_obj.experiment.database_add(spike_clusters_doc);

		% 	disp(['----' num2str(numclusters) ' neuron(s) found----'])

		% 	for nNeuron=1:numclusters

		% 		disp(['--------NEURON_' num2str(nNeuron) '--------'])
                

		% 		neuron_thing = ndi_thing_timeseries(ndi_app_spikesorter_obj.experiment, ['neuron_' num2str(nNeuron)], ndi_timeseries_obj.reference, 'neuron', ndi_timeseries_obj, 0);
		% 		doc = neuron_thing.newdocument();
		% 		%%% TODO: add properties like epoch and stuff?
		% 		ndi_app_spikesorter_obj.experiment.database_add(doc);

		% 		et = ndi_timeseries_obj.epochtable;
				
		% 		neuron_times_idxs = find(clusterids == nNeuron);
		% 		neuron_spiketimes = times(neuron_times_idxs);
                
    %     disp(['---Number of Spikes ' num2str(length(neuron_spiketimes)) '---'])
				
		% 		[neuron, mydoc] = neuron_thing.addepoch(...
		% 			et(1).epoch_id, ...
		% 			et(1).epoch_clock{1}, ...
		% 			et(1).t0_t1{1}, ...
		% 			neuron_spiketimes(:), ...
		% 			ones(size(neuron_spiketimes(:)))...
		% 		);
			
		% 	end
			
		% 	neuron

		% 	neuron1 = ndi_app_spikesorter_obj.experiment.getthings('thing.name','neuron_1');
		% 	% neuron2 = ndi_app_spikesorter_obj.experiment.getthings('thing.name','neuron_2');

		% 	[d1,t1] = readtimeseries(neuron1{1},1,-Inf,Inf);
		% 	% [d2,t2] = readtimeseries(neuron2{1},1,-Inf,Inf);

		% 	figure(10)
		% 	plot(t1,d1,'ko');
		% 	title([neuron.name]);
		% 	ylabel(['spikes']);
		% 	xlabel(['time (s)']);
		% end %function

		% 	%%% TODO: function add_sorting_doc

		% function sorting_doc = add_sorting_doc(ndi_app_spikesorter_obj, sort_name, sort_params)
		% 	% ADD_SORTING_DOC - add sorting parameters document
		% 	%
		% 	% SORTING_DOC = ADD_SORTING_DOC(NDI_APP_SPIKESORTER_OBJ, SORT_NAME, SORT_PARAMS)
		% 	%
		% 	% Given SORT_PARAMS as either a structure or a filename, this function returns
		% 	% SORTING_DOC parameters as an NDI_DOCUMENT and checks its fields. If SORT_PARAMS is empty,
		% 	% then the default parameters are returned. If SORT_NAME is already the name of an existing
		% 	% NDI_DOCUMENT then an error is returned.
		% 	%
		% 	% SORT_PARAMS should contain the following fields:
		% 	% Fieldname              | Description
		% 	% -------------------------------------------------------------------------
		% 	% num_pca_features (10)     | Number of PCA features to use in klustakwik k-means clustering
		% 	% interpolation (3)       | Interpolation factor
		% 	% 
		% 		if nargin<3,
		% 			sort_params = [];
		% 		end;

		% 			% search for any existing documents with that name; any doc that has that name and sorting_parameters as a field
		% 		sort_searchq = ndi_query('ndi_document.name','exact_string',sort_name,'') & ...
		% 			ndi_query('','isa','sorting_parameters','');
		% 		mydoc = ndi_app_spikesorter_obj.experiment.database_search(sort_searchq);
		% 		if ~isempty(mydoc),
		% 			error([int2str(numel(mydoc)) ' sorting_parameters documents with name ''' sort_name ''' already exist(s).']);
		% 		end;

		% 		% okay, we can build a new document

		% 		if isempty(sort_params),
		% 			sort_params = ndi_document('apps/spikesorter/sorting_parameters') + ...
		% 				ndi_app_spikesorter_obj.newdocument();
		% 			% this function needs a structure
		% 			sort_params = sort_params.document_properties.sorting_parameters; 
		% 		elseif isa(sort_params,'ndi_document'),
		% 			% this function needs a structure
		% 			sort_params = sort_params.document_properties.sorting_parameters; 
		% 		elseif isa(sort_params, 'char') % loading struct from file 
		% 			sort_params = loadStructArray(sort_params);
		% 		elseif isstruct(sort_params),
		% 			% If sort_params was inputed as a struct then no need to parse it
		% 		else
		% 			error('unable to handle sort_params.');
		% 		end

		% 		% now we have a sort_params as a structure

		% 		% check parameters here
		% 		fields_needed = {'num_pca_features','interpolation'};
		% 		sizes_needed = {[1 1], [1 1]};

		% 		[good,errormsg] = hasAllFields(sort_params,fields_needed, sizes_needed);

		% 		if ~good,
		% 			error(['Error in sort_params: ' errormsg]);
		% 		end;

		% 		% now we need to convert to an ndi_document

		% 		sorting_doc = ndi_document('apps/spikesorter/sorting_parameters','sorting_parameters',sort_params) + ...
		% 			ndi_app_spikesorter_obj.newdocument() + ndi_document('ndi_document','ndi_document.name',sort_name);

		% 		ndi_app_spikesorter_obj.experiment.database_add(sorting_doc);

		% 		sorting_doc.document_properties,

		% end; % add_sorting_doc




		% function b = clear_sort(ndi_app_spikesorter_obj, ndi_probe_obj, epoch, sort_name)
		% % CLEAR_SORT - clear all 'sorted spikes' records for an NDI_PROBE_OBJ from experiment database
		% %
		% % B = CLEAR_SORT(NDI_APP_SPIKESORTER_OBJ, NDI_EPOCHSET_OBJ)
		% %
		% % Clears all sorting entries from the experiment database for object NDI_PROBE_OBJ.
		% %
		% % Returns 1 on success, 0 otherwise.

		% 	% Look for any docs matching extraction name and remove them
		% 	% Concatenate app query parameters and sort_name parameter
		% 	searchq = cat(2,ndi_app_spikesorter_obj.searchquery(), ...
		% 		{'spike_sort.sort_name', sort_name, 'spike_sort.epoch', epoch});

		% 	% Concatenate probe query parameters
		% 	searchq = cat(2, searchq, ndi_probe_obj.searchquery());

		% 	% Search and get any docs
		% 	mydoc = ndi_app_spikesorter_obj.experiment.database_search(searchq);

		% 	% Remove the docs
		% 	if ~isempty(mydoc),
		% 		for i=1:numel(mydoc),
		% 			ndi_app_spikesorter_obj.experiment.database_rm(mydoc{i}.id())
		% 		end
		% 		warning(['removed ' num2str(i) ' doc(s) with same extraction name'])
		% 		b = 1;
		% 	end
		% end % clear_sort()

		% function waveforms = load_spikewaves_epoch(ndi_app_spikesorter_obj, ndi_timeseries_obj, epoch, extraction_name)
		% 	waveforms = ndi_app_spikeextractor(ndi_app_spikesorter_obj.experiment).load_spikewaves_epoch(ndi_timeseries_obj, epoch, extraction_name);
		% end

		% function times = load_spiketimes_epoch(ndi_app_spikesorter_obj, ndi_timeseries_obj, epoch, extraction_name)
		% 	times = ndi_app_spikeextractor(ndi_app_spikesorter_obj.experiment).load_spiketimes_epoch(ndi_timeseries_obj, epoch, extraction_name);
		% end

		% function spikes = load_spikes(ndi_app_spikesorter_obj, name, type, epoch, extraction_name)
		% 	probe = ndi_app_spikesorter_obj.experiment.getprobes('name',name,'type',type); % can add reference
		% 	spikes = ndi_app_spikeextractor(ndi_app_spikesorter_obj.experiment).load_spikes(probe{1}, epoch, extraction_name);
		% end

		% function spikes = load_times(ndi_app_spikesorter_obj, name, type, epoch, extraction_name)
		% 	probe = ndi_app_spikesorter_obj.experiment.getprobes('name',name,'type',type); % can add reference
		% 	spikes = ndi_app_spikeextractor(ndi_app_spikesorter_obj.experiment).load_times(probe{1}, epoch, extraction_name);
		% end

	end % methods

end % ndi_app_spikesorter
