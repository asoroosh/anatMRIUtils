clear
addpath('/Users/sorooshafyouni/Home/matlab/fieldtrip')
ft_defaults
mri  = ft_read_mri('/Users/sorooshafyouni/Desktop/HCP/100307/unprocessed/3T/T1w_MPR1/100307_3T_T1w_MPR1.nii.gz');
% use the ft_volumereslice function to be able to plot the MRI with the top of the head upwards
% cfg              = [];
% cfg.dim          = [256 256 256];                 % original dimension
% mri              = ft_volumereslice(cfg,mri);
mri.coordsys     = 'spm';

% obtain the brain, skull and scalp tissues
cfg              = [];
cfg.output       = {'tpm'};
cfg.write        = 'yes'; 
cfg.name         = 'test';
bss              = ft_volumesegment(cfg, mri);     % the mri is the same as in the code before

% cfg              = [];
% cfg.funparameter = 'brain';
% cfg.location     = 'center';
% ft_sourceplot(cfg, bss);
