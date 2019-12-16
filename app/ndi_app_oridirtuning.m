classdef ndi_app_oridirtuning < ndi_app

	properties (SetAccess=protected,GetAccess=public)

	end % properties

	methods

		function ndi_app_oridirtuning_obj = ndi_app_oridirtuning(varargin)
			% NDI_APP_ORIDIRTUNING - an app to calculate and analyze orientation/direction tuning curves
			%
			% NDI_APP_ORIDIRTUNING_OBJ = NDI_APP_ORIDIRTUNING(EXPERIMENT)
			%
			% Creates a new NDI_APP_ORIDIRTUNING object that can operate on
			% NDI_EXPERIMENTS. The app is named 'ndi_app_oridirtuning'.
			%
				experiment = [];
				name = 'ndi_app_oridirtuning';
				if numel(varargin)>0,
					experiment = varargin{1};
				end
				ndi_app_oridirtuning_obj = ndi_app_oridirtuning_obj@ndi_app(experiment, name);

		end % ndi_app_oridirtuning() creator


		function tuning_doc = calculate_tuning_curve(ndi_app_oridirtuning_obj, ndi_thing_obj, varargin)
			% CALCULATE_TUNING_CURVE - calculate an orientation/direction tuning curve from stimulus responses
			%
			% TUNING_DOC = CALCULATE_TUNING_CURVE(NDI_APP_ORIDIRTUNING_OBJ, NDI_THING)
			%
			% 
				tuning_doc = {};

				E = ndi_app_oridirtuning_obj.experiment;
				rapp = ndi_app_tuning_response(E);

				q_rthing = ndi_query('depends_on','depends_on','thing_id',ndi_thing_obj.id());
				q_rdoc = ndi_query('','isa','ndi_document_stimulus_response_scalar.json','');
				rdoc = E.database_search(q_rdoc&q_rthing);

				for r=1:numel(rdoc),
					if is_oridir_stimulus_response(ndi_app_oridirtuning_obj, rdoc{r}),
						independent_parameter = {'angle'};
						independent_label = {'direction'};
						constraint = struct('field','sFrequency','operation','hasfield','param1','','param2','');
						tuning_doc{end+1} = rapp.tuning_curve(rdoc{r},'independent_parameter',independent_parameter,...
							'independent_label',independent_label,'constraint',constraint);
					end;
				end;

		end; % calculate_tuning_curve()

		function oriprops = calculate_all_oridir_indexes(ndi_app_oridirtuning_obj, ndi_thing_obj);
			% 
			%
				oriprops = {};
				E = ndi_app_oridirtuning_obj.experiment;
				rapp = ndi_app_tuning_response(E);

				q_rthing = ndi_query('depends_on','depends_on','thing_id',ndi_thing_obj.id());
				q_rdoc = ndi_query('','isa','ndi_document_stimulus_response_scalar.json','');
				rdoc = E.database_search(q_rdoc&q_rthing);


				for r=1:numel(rdoc),
					if is_oridir_stimulus_response(ndi_app_oridirtuning_obj, rdoc{r}),
						% find the tuning curve doc
						q_tdoc = ndi_query('','isa','ndi_document_stimulus_tuningcurve.json','');
						q_tdocrdoc = ndi_query('stimulus_response_scalar_reference','exact_string',rdoc{r}.id(),'');
						tdoc = E.database_search(q_tdoc&q_tdocrdoc&q_rthing);
						for t=1:numel(tdoc),
							oriprops{end+1} = calculate_oridir_indexes(ndi_app_oridirtuning_obj, tdoc{t});
						end;
					end;
				end;

		end; % calculate_all_oridir_indexes()

		function oriprops = calculate_oridir_indexes(ndi_app_oridirtuning_obj, tuning_doc)
			% CALCULATE_ORIDIR_INDEXES 
			%
			%
			%
				E = ndi_app_oridirtuning_obj.experiment;
				tapp = ndi_app_tuning_response(E);
				ind = {};
				ind_real = {};
				control_ind = {};
				control_ind_real = {};
				response_ind = {};
				response_mean = [];
				response_stddev = [];
				response_stderr = [];

				stim_response_doc = E.database_search(ndi_query('ndi_document.id', 'exact_string',...
					tuning_doc.document_properties.stimulus_response_scalar_reference,''));

				if isempty(stim_response_doc),
					error(['cannot find stimulus response document. Do not know what to do.']);
				end;

				% grr..if the elements are all the same size, Matlab will make individual_response_real, etc, a matrix instead of cell
				tuning_doc = tapp.tuningdoc_fixcellarrays(tuning_doc);

				for i=1:numel(tuning_doc.document_properties.tuning_curve.individual_responses_real),
					ind{i} = tuning_doc.document_properties.tuning_curve.individual_responses_real{i} + ...
						sqrt(-1)*tuning_doc.document_properties.tuning_curve.individual_responses_imaginary{i};
					ind_real{i} = ind{i};
					if any(~isreal(ind_real{i})), ind_real{i} = abs(ind_real{i}); end;
					control_ind{i} = tuning_doc.document_properties.tuning_curve.control_individual_responses_real{i} + ...
						sqrt(-1)*tuning_doc.document_properties.tuning_curve.control_individual_responses_imaginary{i};
					control_ind_real{i} = control_ind{i};
					if any(~isreal(control_ind_real{i})), control_ind_real{i} = abs(control_ind_real{i}); end;
					response_ind{i} = ind{i} - control_ind{i};
					response_mean(i) = nanmean(response_ind{i});
					if ~isreal(response_mean(i)), response_mean(i) = abs(response_mean(i)); end;
					response_stddev(i) = nanstd(response_ind{i});
					response_stderr(i) = nanstderr(response_ind{i});
					if any(~isreal(response_ind{i})),
						response_ind{i} = abs(response_ind{i});
					end;
				end;

				resp.ind = ind_real;
				resp.blankind = control_ind_real{1};
				[anova_across_stims, anova_across_stims_blank] = neural_response_significance(resp);

				response.curve = ...
					[ tuning_doc.document_properties.tuning_curve.independent_variable_value(:)' ; ...
						response_mean ; ...
						response_stddev ; ...
						response_stderr; ];
				response.ind = response_ind;

				vi = oridir_vectorindexes(response);
				fi = oridir_fitindexes(response);

				properties.coordinates = 'compass';
				properties.response_units = tuning_doc.document_properties.tuning_curve.response_units;
				properties.response_type = stim_response_doc{1}.document_properties.stimulus_response_scalar.response_type;

				tuning_curve = struct('direction', rowvec(tuning_doc.document_properties.tuning_curve.independent_variable_value), ...
					'mean', response_mean, ...
					'stddev', response_stddev, ...
					'stderr', response_stderr, ...
					'individual', {response_ind}, ...
					'raw_individual', {ind_real}, ...
					'control_individual', {control_ind_real});

				significance = struct('visual_response_anova_p',anova_across_stims_blank,'across_stimuli_anova_p', anova_across_stims);

				vector = struct('circular_variance', vi.ot_circularvariance, ...
					'direction_circular_variance', vi.dir_circularvariance', ...
					'Hotelling2Test', vi.ot_HotellingT2_p, ...
					'orientation_preference', vi.ot_pref, ...
					'direction_preference', vi.dir_pref, ...
					'direction_hotelling2test', vi.dir_HotellingT2_p, ...
					'dot_direction_significance', vi.dir_dotproduct_sig_p);

				fit = struct('double_guassian_parameters', fi.fit_parameters,...
					'double_gaussian_fit_angles', rowvec(fi.fit(1,:)), ...
					'double_gaussian_fit_values', rowvec(fi.fit(2,:)), ...
					'orientation_preferred_orthogonal_ratio', fi.ot_index, ...
					'direction_preferred_null_ratio', fi.dir_index, ...
					'orientation_preferred_orthogonal_ratio_rectified', fi.ot_index_rectified', ...
					'direction_preferred_null_ratio_rectified', fi.dir_index_rectified, ...
					'orientation_angle_preference', mod(fi.dirpref,180), ...
					'direction_angle_preference', fi.dirpref, ...
					'hwhh', fi.tuning_width);

				oriprops = ndi_document('vision/oridir/ndi_document_orientation_direction_tuning', ...
					'orientation_direction_tuning', var2struct('properties', 'tuning_curve', 'significance', 'vector', 'fit') + ...
					ndi_app_oridirtuning_obj.newdocument();
					oriprops = oriprops.set_dependency_value('thing_id', stim_response_doc.dependency_value('thing_id'));

				E.database_add(oriprops);

				figure;
				ndi_app_oridirtuning_obj.plot_oridir_response(oriprops);

		end; % calculate_oridir_indexes()

		function b = is_oridir_stimulus_response(ndi_app_oridirtuning_obj, response_doc)
			%
				E = ndi_app_oridirtuning_obj.experiment;
					% does this stimulus vary in orientation or direction tuning?
				stim_pres_doc = E.database_search(ndi_query('ndi_document.id', 'exact_string', dependency_value(response_doc, 'stimulus_presentation_id'),''));
				if isempty(stim_pres_doc),
					error(['empty stimulus response doc, do not know what to do.']);
				end;
				stim_props = {stim_pres_doc{1}.document_properties.stimuli.parameters};
				% need to make this more general TODO
				included = [];
				for n=1:numel(stim_props),
					if ~isfield(stim_props{n},'isblank'),
						included(end+1) = n;
					elseif ~stim_props{n}.isblank,
						included(end+1) = n;
					end;
				end;
				desc = structwhatvaries(stim_props(included));
				b = eqlen(desc,{'angle'});
		end; % is_oridir_stimulus_response

		function plot_oridir_response(ndi_app_oridirtuning_obj, oriprops_doc)

				E = ndi_app_oridirtuning_obj.experiment;

				h = myerrorbar(oriprops_doc.document_properties.orientation_direction_tuning.tuning_curve.direction, ...
					oriprops_doc.document_properties.orientation_direction_tuning.tuning_curve.mean, ...
					oriprops_doc.document_properties.orientation_direction_tuning.tuning_curve.stderr, ...
					oriprops_doc.document_properties.orientation_direction_tuning.tuning_curve.stderr);

				delete(h(2));
				set(h(1),'color',[0 0 0]);

				hold on;
				baseline_h = plot([0 360],[0 0],'k--');
				fitline_h = plot(oriprops_doc.document_properties.orientation_direction_tuning.fit.double_gaussian_fit_angles,...
					oriprops_doc.document_properties.orientation_direction_tuning.fit.double_gaussian_fit_values,'k-');
				box off;

				thing_doc = E.database_search(ndi_query('ndi_document.id','exact_string',dependency_value(oriprops_doc,'thing_id'),'')); 
				if isempty(thing_doc),
					error(['Empty thing document, don''t know what to do.']);
				end;
				thing = ndi_document2thing(thing_doc{1}, E);
				xlabel('Direction (\circ)');
				ylabel(oriprops_doc.document_properties.orientation_direction_tuning.properties.response_units);
				title([thing.thingstring() '; ' oriprops_doc.document_properties.orientation_direction_tuning.properties.response_type]);

		end; % plot_oridir_response

	end; % methods

	methods (Static),
		

	end; % static methods

end % ndi_app_oridirtuning


