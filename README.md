 
scopa
 
updated carl wienecke 240313


TO DO:
--filling GPU without time increase
--sh folder
--requeue save/load
--deepcad GOF
--automated O2 memory/time request based on file size
--proper caiman averaging
--shared python matlab engine
--O2 paralellization along arbitrary dimension, not just along recordings 
--submit cxp with ssh
--population analysis
--integrate into flyg


limitations:
--does not accept 2-channel data (should be easy to allow though)
--does not use virmen (should be easy to allow though)
--very little population analysis (mostly single roi)

############################## GENERAL ######################################

analysis pipeline for volumetric (xyzt) 2p imaging while presenting visual stimuli with G4 panels and measuring locomotion with fictrac

the pipeline can be automated, except for an option to draw morphological rois, and an option to crop the FOV
the pipeline has various features for paralellization on O2 
the pipeline has various features for parameter exploration

############################## AUTOMATED FILE TRANSFER ######################################

automated file transfer is intended to make batch mode on O2 (running cxp.sh) more convenient, although it can be used on O2 or local, and in interactive or batch mode


if do_copyfiles==1 no computation occurs, but the pipeline will automatically copy whatever files you need from a storage location to a compute location, if do_copyfiles==0 computation occurs, but no copy occurs, if do_copyfiles==2 no computation occurs, but any new files are copied back into storage location . . . the relevant files are determined by the pipeline module you're running

to use do_copyfiles=1 or do_copyfiles=2 on O2, you must have access to the transfer job partition (write rchelp@hms.harvard.edu to request access to the transfer job partition)

if files have the same name but their modification times differ by more than one second, the copy will overwrite the detination file with the source file 

if files have the same name and same modification times, no copy occurs 

files that exist in destination but not source will remain in destination (since it's a per-file copy not a directory sync) 

  the storage server onto O2, and then any new files get copied back to storage server

        files are copied from storage location (e.g. wilson lab stoarge server)
                pth_storage_prefix/folder_with_all_recordings_on_storage_and_compute_filesystems/**/folder_with_data/
        into compute location (e.g. O2)
                pth_to_your_scratch_folder/folder_with_all_recordings_on_storage_and_compute_filesystems/**/folder_with_data/
        where ** can be any level of nesting, including none 

for example, copy from here 
        /n/files/Neurobio/wilsonlab/wienecke/stacks/20230627-3_D05_syt7f_018_syt7f/20230627_3_1_raw.tif
to here 
        /n/scratch/users/c/caw846/stacks/stacks/20230627-3_D05_syt7f_018_syt7f/20230627_3_1_raw.tif

do_copyfiles will mirror on O2 the storage directory above requested file up to folder_with_all_recordings_on_storage_and_compute_filesystems
if necessary, will create parent direcotries without error 

do_copyfiles=1 copies into but does no analysis , do_copyfiles=0 does the analysis, do_copyfiles=2 copies everything new back out (DOES NOT OVERWRITE, UNLESS SHARING THE SAME NAME IN SOURCE AND DESTINATION)

do not put files with the same name in different locations under these directories

please have a backup of your data outside of the paths this pipeline operates on (path_storage and scratch )
especially if you are using do_copyfiles to automate file transfer to and from O2, 

do_copyfiles may not work well for large transfers (judging by the wording on the O2 website), but for this pipeline, i've had no problems 
 
do_copyfiles occurs inside pipeline_init.py for two reasons:
        1. to ensure everything is the same for the copying and the analysis (ie to ensure the right files get copied)
        2. since slurm arrays are used, it is simpler to copy inside the parallel job


############################## INPUT ######################################

input to whole pipeline (ie input to register.py) is raw tif output by scan image, saved with flyg formatting, or scopa formatting

this is flyg formatting
        20230627-3_D05_syt7f_018_syt7f_194418_trial_001_00001.tif
this is scopa formatting
        20230627_3_1_raw.tif

key file identifiers are recdate, fly, and trial (these are params used to find files in pipeline_init.py, and cxp.sh)

this file must be in a data folder that it within folder_with_all_recordings_on_storage_and_compute_filesystems
the data folder can have any name pattern
by default folder_with_all_recordings_on_storage_and_compute_filesystems='stacks'
on carl has pth_storage_prefix = '/n/files/Neurobio/wilsonlab/wienecke/'
so for example, the following is valid input file on storage server (can be automatically moved to a compute filesystem, like O2, if do_scopyfiles=1)


/n/files/Neurobio/wilsonlab/wienecke/stacks/20230627-3_D05_syt7f_018_syt7f/20230627_3_1_raw.tif

and for example, the following is valid input file on O2 (if you're not using do_copyfiles)

/n/scratch/users/c/caw846/stacks/stacks/20230627-3_D05_syt7f_018_syt7f/20230627_3_1_raw.tif

############################## INTERACTIVE VS BATCH MODE ######################################

for running the pipeline in interactive mode . . . 
        entry point is pipeline_init.py for 'pre' pipeline (input raw imaging tif)
                you can run on your local machine (e.g. in vscode), or on O2Portal (e.g., in vscode)
                adjust input params in file default_params_interactive.py
        entry point is a2p.m for 'post' pipeline (input raw imaging tif, or output files from 'pre')
                you can run on your local machine (in matlab), or on O2Portal (in matlab)
        if you install 3rd-party libraries (like caiman or deepcad) as conda environments, rather than dev mode 
                install, you can still step through the code during debugging in vscode if you add this line to file 
                launch.json, which is in hidden folder .vscode, in the scopa repo 
                        "justMyCode": false
                in general this is how you step through 3rd-party libraries during debugging in VS code, the dev mode install let's you step into code without adding this line, and makes changing the code easier
                the shared caiman on O2 is dev mode, so you don't need this line on o2 
        in interactive mode on O2, if you want to do_copyfiles 1 or 2 (to debug the copying for example) make sure you choose 
                the transfer partition when setting up vscode (and set do_copyfiles to 1 or 2 in input_params_interactive)
        if you are running on your local machine, you can't use deepcad denoising unless you have a gpu, 
                so most likely only have to install caiman and a few other small packages locally (see installation below)

for running the pipeline in batch (non-interactive) mode . . . 
        entry point is cxp.sh (calls pipeline_init.py)
        set input params in cxp.sh
        default_params_batch.py is invoked in this case, but do not ever adjust params in this file 
        the pipeline has a script (cxp.sh) that lets you string together jobs on O2  (in any application or language available on O2), cxp.sh handles parallelization, job dependencies, resource  allocation, all automatically
        so cxp.sh is useful as a master pipeline script, for running this pipeline in non-interactive mode 
        cxp.sh and has a simple layout that can be extended/adpated 
        call it by typing cxp.sh in the O2 command line 

also note the term "interactive mode" can be misleading, because you can still run a batch, automated, for example if you use wildcards in your file specifiers, and you've already defined regionex (or they're all 'fullfov') then it will run through all found files, whether in interactive mode or batch mode


############################## INTERACTIVE ON O2 ######################################

to run interactively on O2, use VS Code on O2 (to debug on O2, or to do_cropping_session), you'll be promted to fill out several fields
most of them are intuitive, except for two fields at the bottom
here's the values i use for these two fields for caiman or deepcad

also be sure to set justmycode to false in launch.json, this will allow you to step into 3rd party libraries during debugging
launch.json can be found in the vscode file explorer, in scopa/vscode; it is a hidden file 

for caiman registration or source extraction:
        
        Additional modules to be preloaded:
                python/3.10.11

        leave Slurm Custom Arguments blank

        Custom Environment (drag text area to enlarge):
                eval "$(/n/data1/hms/neurobio/wilson/miniforge3/bin/conda shell.bash hook)"
                conda activate caiman


for deepcad denoising (if you want to step into deepcad code during VSCode debugging, make "justMyCode": false in launch.json):

        Additional modules to be preloaded:
                gcc/9.2.0 python/3.9.14 cuda/11.7

        leave Slurm Custom Arguments blank

        Custom Environment (drag text area to enlarge):
                eval "$(/n/data1/hms/neurobio/wilson/miniforge3/bin/conda shell.bash hook)"
                conda activate deepcad


############################## BATCH ON O2 ######################################

run ./cxp.sh in command line on O2 
see cxp.sh for docs
cxp.sh calls pipeline_init.py

 since the different submodules of the pipeline require very different resources on O2, cxp runs each module as a separate sbatch job with different resources; these jobs depend on each other

############################## PIPELINE ORGANIZATION ######################################


there are two main sub-pipelines: 

'pre': 

in folder pre, mostly python, entrypoint is pipeline_init.py in interactive mode (run VS code on O2 portal), or cxp.sh in batch mode (run ./cxp.sh on O2 command line . . . cxp.sh calls pipeline_init.py), 'pre' preprocesses imaging data, takes raw imaging data as only input, has the following modules:
                --registration (caiman Normcorre), with line-by-line background subtraction and temporal 
                        smoothing submodules to deal with noisy recordings, prior to registration 
                --denoising (deepcadrt), with "best model" selection
                --remove scan noise with line by line fft (for very noisy recordings, structured scan noise may appear after denoising )
                --source extraction (caiman cnmf)
'post': 

in folder post, mostly matlab, entrypoint is a2p.m, operates on raw imaging data and/or on output of 'pre', and also optional stimulus and behavior data, has the following modules:
                --plotting output from 'pre' pipeline as gif (compare raw, registered, denoised in one figure)
                --basic statistical metrics for output from 'pre' pipeline 
                --morphological roi extraction (manual drawing or automated, or an interaction)
                --caiman functioal roi loading and selection, and optional clustering according to morphological rois 
                --roi response normalization 
                --bump computation: fitting roi preferred heading, resampling compass, then vector average, using any type of roi 
                --input/output timeseries model fitting: various model architectures (including fnet) using matlab global optimization toolbox; models can be fit to each roi, or each pixel, or both, with various plots for comparison
                --2d or 3d scatterplots for all available timeseries
                --various diagnostic figures throughout these submodules aimed at building intuition for the data 



############################## PARALLELIZATION ON O2 ######################################

 if recording_index = 'all', pipeline_init.py cycles through all recordings in directory pth_allrec, passing one trial at a time to pipeline in pipeline.py

 if recording_index is not 'all', pipeline_init.py chooses only the recording matching value of recording_index, based on the sorted list of all recordings matching recdates, fly, trial pattern in pth_allrec

 this is convenient because recording_index can be assigned SLURM_ARRAY_TASK_ID in a bash script (e.g. mcp.sbatch), 
 which will run the pipeline on multiple recordings in parallel as a job array on O2 

 for example, the line SBATCH --array=[1-30] will run up to 30 jobs (or as many as resources will allow) in parallel for recordings (date_fly_trial) with recording_index 1-30  


############################## REGISTRATION ######################################

--register.py, called from pipeline init when do_register==1
--input to register (and, thus, whole pipeline) are the tif files output by ScanImage (precision is int16, not uint16), dimensions are tzyx
--input filename must be the following format:

 metadata is read from these raw tif files in read_save_metadata.py
https://github.com/flatironinstitute/CaImAn/blob/main


############################## DENOISING ######################################

--denoise.py, called from pipeline init when do_denoise==1
--the denoising requires motion corrected input tif (suffix cmrg_.tif)
--denoising folder is separate from data folder because it can get big (if multiple epochs are used to denoise)
--see additional documentation in denoise.py
https://github.com/cabooster/DeepCAD-RT


############################## SOURCE EXTRACTION ######################################

--extract.py, called from pipeline init when do_extract==1
https://github.com/flatironinstitute/CaImAn/blob/main
--extraction requires either the motion correction output tif (suffix cmrg_.tif), or the denoising output tif (suffix cmrg_dcdn_.tif), depending on whether use_denoised is true of false
 --extraction can operate on 4d xyzt data (planar_extraction = False), or 3d data xyt (planar_extraction = True), where extraction operates on each z plane of the 4d data independently
 --extraction requires either the motion correction output tif, or the denoising output tif (depending on whether use_denoised is true of false)
--if regionex is not ['fullfov'], interactive plots prompt user to define regionex by setting croplim 
 regionex is a cuboid or rectangular subset of the FOV on which extraction is run (on subsequent runs, these are loaded automatically, but will error if there are multiple different croplim with the same regionex name) 
 --you can specify regionex 'fullfov' to use the whole FOV and skip drawing  
 --user can define multiple regionex
--so, here, regionex is meant to separately run extraction on regions requiring different extraction params, and/or to run the extraction faster (ie if all extraction_regions amount to less data than the full fov)  
--then, analysis of more precisely defined brain regions is done in 'post', where regions can be further split into arbitrary 2d, 3d, or 4d shapes
 --if multiple regionex are provided, the extraction part of the pipeline loops over these   
 --the extraction part of the pipeline also includes the option to loop over all possible combinations of any subset of extraction parameters, defined in map2opt.py
 --to do this, set optex_sweep to a negative value, and all param combinations up to that index are looped over 
 --if optex_sweep is positive, only that param set index is run (if 'default', onlt the default param set is run) 

 

############################## OUTPUT FILES ######################################

 some output files of this pipeline are saved as uint16 (not int16), since the data is nonnegative after processing
 in all stages of the pipeline. int16 or uint16 data is converted to float32 when read in, then operated on

 register outputs registered tif, suffix cmrg_.tif (if background subtraction is used, suffix bksb_cmrg_.tif)
 denoise outputs denoised tif, suffix cmrg_dcdn_.tif (if background subtraction is used, suffix bksb_cmrg_dcdn_.tif)
 extract outputs mat files, suffix rois_.mat (different mat file for each extraction param set)

############################## CROPPING SESSION ######################################

 do_crop_only = True will skip everything but this interactive FOV selection for all entries in regionex (and all recordings), but must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, to provide input files for cropping  

 do_crop_only = True is convenient to cycle through many recordings that have been motion corrected (and optionally denoised), but have not been extracted, and you want to run the extraction on all of them without interruption in a separate job after the cropping session 
 

############################## POST SUB-PIPELINE ######################################

post detailed notes are not well organized yet 

entrypoint is a2p.m
'post' operates on any/all regionex for any recording, or new regionex, if new regionex are listed as input to 'post'

 if a regionex rectangle or cuboid cannot well separate brain regions that you want separated in later analysis, 'post' gives the option to further sebset/subdivide any regionex with free drawn rois (we don't do that here because caiman cannot operate on irregularly shaped FOV)

 hires is not processed in python; in matlab it is registered to the registered stack; this seemed simpler 


#a2p.m is the entry point to the 2nd half of the analysis analysis pipeline for volumetric xyzt 2p imaging data with behavior and stimulus
#first part (motion correction, denoising, and source extraction) is in python, entry point pipeline_init.py:

##a2p.m loads output files from python pipeline,
##if high-z-res stack exists, it can be used to aid with morphological identification
#register it in 3d (here in matlab) to caiman-registered functional stack
##(didn't see the point of registering it in python/caiman)

##for each regionex, draw 2d mask
##3d mask is automatically extracted (using hi-z-res stack if it exists, otherwise just the lo-z-res)
##use 3d mask to define morphological rois, which can optionally be used in response quantification
##normalize responses
##map functional rois to mophological rois, if desired
##written to cycle through all source extraction files (different params) and cycle through all normalization methods, and compare all of them
##since it can be hard to intuit the optimal settings

#Hi-z-res stack is only useful for mapping multiple morphological ROIs
#Because hires can help increase z res in the interior of the region if functional ROIs span multiple lo res planes (def flawed though)
#But won't help at the region exterior since you don't know where lores roi ends

#rois can be morphological or functional
#morphological rois are clustered
#functional rois are clustered
#some

#note remove_scan_noise should ideally only occur prior to
#caiman roi extraction, but this pipeline allows the user to run remove_scan_noise afterwards 
#(need to fix this so the user has the option to use nosn suffix stack for roi extraction)

#rval documentation The algorithm also measures the reliability of the spatial mask by comparing the filters in A
#with the average of the movies over samples where exceptional events happen, after  removing (if possible)
#frames when neighboring neurons were active

##g4 frame 0 (in vis.raw) assigned to angle -pi (in vis.yaw)




############################## JUPYTER ######################################

 a somewhat outdated version of the python part of the pipeline also exists as a jupyter notebook (pipeline_nb.ipynb), 
 it is mostly the same but the fov selection plots use different packages, 
 and it uses fewer loops and is less automated 
 BUT, i've been unable to get the denoising working in the ipynb version of the pipeline on O2 (it does work on google colab though)


############################## EXTRA NOTES ######################################

there are a few spots in the pipeline built to accommodate carl's old project, they are flagged with carls_old_project==1, and in some cases have their own functions (which are named with suffix 'carls_old_project') 


############################## INSTALLING THINGS ######################################

 
the pipeline uses caiman and deepcad dependencies that are on our shared wilson lab folder, so if you're running scopa on O2, you don't have to install any dependencies, except scopa itself 

git clone scopa, recommended location is home folder on O2, or home folder on local machine 

 before running register and extract on your local machine, caiman and a few other packages need to be installed; to do that, log into O2 compute cluster and run these commands from your home folder 

follow these instructions to install caiman
https://github.com/flatironinstitute/CaImAn/blob/main/docs/source/Installation.rst
you can install with conda, or as dev-mode 
in dev-mode you will be able to step into the code and debug and edit it more easily 
if you don't want to do that, just do conda install 
you also need to install a few extra packages into the caiman environment, so activate the environment and use pip, like this
            conda activate caiman
            pip install scanimage-tiff-reader
            pip install mat73
            pip install natsort


if you ever want to install your own version of deepcad, not the shared wilson lab copy, follow these instructions 
https://github.com/cabooster/DeepCAD-RT
if you do this, you will also need to install a few extra pip packages, after activating the environment 
            conda activate deepcadrt
            pip install mat73
            pip install matplotlib 
            pip install natsort
            pip install scanimage-tiff-reader

if you install your own, the packages installed with pip while the conda env is active are here on O2 
/home/caw846/.conda/envs/caiman/lib/python3.10/site-packages


############################## MATLAB ENGINE FOR PYTHON ######################################

to run everything through the same pipeline, install the matlab for python engine, which let's you call matlab functions from within python files (i do this so all analysis goes through the same functions for input-based file selection and copying

be sure to pip install the correct matlabengine version for the matlab version on O2 that the pip installer finds by default, which appears to be the newest matlab version on O2, which is 2023a, not 2023b, and which corresponds to matlabengine==9.14.3, which is not the latest matlabengine

start an interactive session, then module load the python version you intend to use first, this pipeline uses 3.10 (never tested other versions)

if matlabengine fails to install where you intend because you don't have write permission, the installer will automatically try installing in your home folder, within hidden folder .locals . . . it should work, and if it works, there will be two new folders in ~/.local/lib/python3.10/site-packages, one called matlab and one called matlabengine-9.14.3.dist-info

move both folders into a path you want the pipeline to find . . . for example, you can move them into a virtual environment (a venv or a conda environment) that the pipeline uses . . . below are the commands to move them into the virtual environment in the shared wilson lab folder that gets loaded for the jobs that use matlab . . . and also how to install some extra packages into the matlab engine venv 

srun -p interactive --pty -t 3:00:00 -c 5 --mem=15G bash
module purge
module load gcc/9.2.0
ml python/3.10.11

cd /n/data1/hms/neurobio/wilson
virtualenv mle --system-site-packages
source /n/data1/hms/neurobio/wilson/mle/bin/activate

pip install matlabengine==9.14.3

mv ~/.local/lib/python3.10/site-packages/matlab /n/data1/hms/neurobio/wilson/miniforge3/envs/caiman/lib/python3.11/site-packages
mv ~/.local/lib/python3.10/site-packages/matlabengine-9.14.3.dist-info /n/data1/hms/neurobio/wilson/miniforge3/envs/caiman/lib/python3.11/site-packages

pip3 install matlabengine==9.14.3
pip3 install mat73
pip3 install natsort
pip3 install scanimage-tiff-reader
pip3 install scipy
pip3 install tifffile
pip3 install opencv-python

that should be all you need to do, but here are some more comments

the docs say to put the matlabengine installation path in LD_LIBRARY_PATH in .bashrc if the matlab app is not in the default location . . . its O2 location does not match what the docs report to be defualt, but i've found matlab engine works without doing this, but i'm documenting it here in case somebody needs it, you just open your hidden .bashrc file and put the export line as the last line (you have to reopen your terminal session for the change to take effect)

cd ~
nano .bashrc
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/n/app/matlab/2023a-v2/bin/glnxa64

in case it's useful to know about install failures, initially i tried pip install with the wrong matlabengine version, which fails, and i also tried running setup.py directly, like this
        cd /n/app/matlab/2023a-v2/extern/engines/python
        python3 setup.py build --build-base=“/home/caw846” install --prefix="/home/caw846/.conda/envs/caiman/lib/python3.10/site-packages/matlab23a”
various versions of this approach failed, some actually installed, but would error when using the code


############################## HOW I INSTALLED DEPENDENCIES IN WILSON LAB SHARED FOLDER ######################################

https://stackoverflow.com/questions/77474450/using-conda-environment-at-a-specific-directory
conda config --append envs_dirs /n/data1/hms/neurobio/wilson/miniforge3/envs
CONDA_ALWAYS_COPY=1 mamba env create -f env1.yaml -p /shared/conda_envs/env1

if you're using -f it's conda env create, if not using -f then it's just conda create 

#MINIFORGE

srun --pty -p interactive -t 0-1:00 --mem=5G bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh
told it not to modify any config files 

#CAIMAN


fork caiman repo and rename caiman (no capitals)
srun --pty -p interactive -t 0-1:00 --mem=5G bash
eval "$(/n/data1/hms/neurobio/wilson/miniforge3/bin/conda shell.bash hook)"
git clone https://github.com/wienecke/caiman
cd caiman/
CONDA_ALWAYS_COPY=1 mamba env create -f environment.yml -p /n/data1/hms/neurobio/wilson/miniforge3/envs/caiman
source activate caiman
pip install -e .
pip install scanimage-tiff-reader
pip install mat73
pip install natsort

#DEEPCAD

CONDA_ALWAYS_COPY=1 mamba create -p /n/data1/hms/neurobio/wilson/miniforge3/envs/deepcad python=3.9
conda activate deepcad
#pip3 install torch torchvision torchaudio #for cuda12.1
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 #for cuda11.7
pip install deepcad

OR INSTEAD OF pip install deepcad, you can

        fork deepcad and clone it, but then you have to pip install all the dependencies (there's around 15-20)


pip install mat73
pip install matplotlib 
pip install natsort
pip install scanimage-tiff-reader

#SCOPA
cd /n/data1/hms/neurobio/wilson
git clone https://github.com/wienecke/scopa.git



############################## GPUS ######################################

current recommendation is the default in cxp.sh
it is rtx6000:1,vram:24G #2nd-lowest vram on gpu_requeue (single precision)
this takes 5.5 hours, but has very little wait time because it's on gpu_requeue partition, which also counts against your fairshare score much less 

teslaM40 on gpu_requeue takes about 12 hours, and has the lowest vram, so your resource request may be more efficient, using this, but rtx6000 is not that large, and it's on requeue so i think it's fine

a100:1,vram:80G is most powerful, only takes about 1:45 to train 5 epochs 10K patches, but wait time can be 2-10 hours, and it's on gpu_quad, and current pipeline only uses a small portion of it's vram (and loading multiple recordings onto same gpu just makes it take proportionately longer, so best option seems to be rtx6000 on gpu_requeue )

#gpu_to_use=a100:1,vram:80G  #fastest on gpu_quad (double precision)
#gpu_to_use=teslaV100s:1,vram:32G #lowest vram on on gpu_quad (double precision)
#gpu_to_use=a100:1,vram:40G #fastest on gpu_requeue (here 40G, but 80G also available) (unnamed precision)
#gpu_to_use=rtx6000:1,vram:24G #2nd-lowest vram on gpu_requeue (single precision)
#gpu_to_use=teslaM40:1,vram:12G #lowest vram on gpu_requeue (probably double precision)
#gpu_to_use=teslaV100:1,vram:16G #fastest on gpu partition (double precision)
#gpu_to_use=teslaM40:1,vram:12G #2nd fastest on gpu partition (also 24G) (double precision)

############################## SHORTCUTS ON O2 ######################################

to save time you can put shortcuts in ~/.bashrc 
open .bashrc and insert shortcuts at bottom of file
for example

# User specific aliases and functions
alias dwc='cd /n/data1/hms/neurobio/wilson/caiman'
alias dwe='cd /n/data1/hms/neurobio/wilson/miniforge3/envs'
alias ss='cd /n/scratch/users/c/caw846/stacks'
alias sd='cd /n/scratch/users/c/caw846/denoising'
alias fw='cd /n/files/Neurobio/wilsonlab/wienecke'
alias hh='cd /home/caw846'
alias hhs='cd /home/caw846/scopa'
alias hhst='cd /home/caw846/scopatmp'
alias in1='srun --pty -p interactive -t 0-1:00 --mem=1G bash'
alias in5='srun --pty -p interactive -t 0-1:00 --mem=5G bash'
alias chook='eval "$(/n/data1/hms/neurobio/wilson/miniforge3/bin/conda shell.bash hook)"'



