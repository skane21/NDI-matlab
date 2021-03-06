function E = ndi_marderlab_hamood_test(ref, dirname)
% NDI_MARDERLAB_HAMOOD_TEST - test reading from Murkherjee et al. 2019
%
% E = NDI_MARDERLAB_HAMOOD_TEST(REF, DIRNAME)
%
% Open a directory from Hamood et al. (2015, Eve Marder lab)
%
% Example:
%   E = ndi_marderlab_hamood_test('/Volumes/van-hooser-lab/Projects/NDI/Datasets_to_Convert/Marder/Data/811/811_05');
%


if nargin==0,
	disp(['No reference or dirname given, using defaults:']);
	ref = '811_105',
	dirname = '/Volumes/van-hooser-lab/Projects/NDI/Datasets_to_Convert/Marder/Data/811/811_105',
end;

E = ndi_marderlab_expdir(ref, dirname); 

d = E.daqsystem_load('name','marder_ced');

et = d.epochtable();

disp(['Found ' int2str(numel(et)) ' epochs.']);

p = E.getprobes()

p{1}

[d,t] = p{1}.readtimeseries(1,0,100); % read first epoch, 100 seconds

figure;
plot_multichan(d,t,400); % plot with 400 units of space between channels
xlabel('Time(s)');
ylabel('Microvolts');
