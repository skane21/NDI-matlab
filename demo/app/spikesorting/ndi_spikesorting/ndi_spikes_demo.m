ndi_globals;
mydirectory = [ndipath filesep 'ndi_common' filesep 'example_app_experiments'];
dirname = [mydirectory filesep 'exp_sg'];
disp(['opening experiment object...']);
E = ndi_experiment_dir('exp1', dirname);
d = E.daqsystem_load('name','SpikeGadgets');
if isempty(d),
	disp(['Now adding our acquisition device (SpikeGadgets):']);
	filenav = ndi_filenavigator(exp, '.*\.rec\>');  % look for .rec files
	dr = ndi_daqreader_mfdaq_spikegadgets;
	dev1 = ndi_daqsystem_mfdaq('SpikeGadgets',filenav, dr);
	exp.daqsystem_add(dev1);
end;

spike_extractor = ndi_app_spikeextractor(exp);
spike_sorter = ndi_app_spikesorter(exp);
probe = exp.getprobes('name','Tetrode7','reference',1,'type','n-trode');
probe = probe{1};

d = E.database_search({'ndi_document.name','test','spike_extraction_parameters.filter_type','(.*)'});
if isempty(d),
	spike_extractor.add_extraction_doc('test');
end;


spike_extractor.extract(probe, 1, 'test', 1)
w = spike_extractor.load_spikewaves_epoch(probe,1,'test');
figure;
plot(w(:,:,1)); 
title(['First spike']);
xlabel('Samples');
ylabel('Amplitude');

%spike_sorter.spike_sort('Tetrode7', 'n-trode', 1, 'test', 'test_sort', 'ndi_common/example_app_experiments/exp_sg/sorting_parameters.txt')