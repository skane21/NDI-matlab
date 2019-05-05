function multiple_epoch_directory = test_ndi_iodevice_image_tiffstack_multipleepoch()
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
ndi_globals;
example_directory = [ndiexampleexperpath];
input_dir_name = [example_directory filesep 'exp_image_tiffstack' filesep 'raw_data' ];
example_exp = ndi_experiment_dir('exp1',input_dir_name);
example_filetree = ndi_filetree(example_exp,'.*\.tif\>');
example_device = ndi_iodevice_image_tiffstack('sampleDevice',example_filetree);
multiple_epoch_directory = example_device.epochfiles_dir;