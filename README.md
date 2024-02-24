 scopa
 
 updated carl wienecke 240218

TO DO:
--filling GPU without time increase
--sh folder
--requeue save/load
--deepcad GOF
--memory allocation based on file size
--integrate matlab pipeline
--shared matlab engine
--submit cxp to O2 from local with ssh 
--integrate into flyg

analysis pipeline for volumetric (xyzt) 2p imaging while presenting visual stimuli and measuring locomotion with fictrac

entrypoint is pipeline_init.py in interactive mode, or cxp.sh in batch mode (cxp.sh calls pipeline_init.py)

there are 7 modules: registration, 

 the second part of the pipeline is in matlab (entry point is a2p.m), and operates on the output of this first part (imaging data) and also behavior and stimulus data

caiman_plots_all (in file vis.py)

 if recording_index = 'all', pipeline_init.py cycles through all recordings in directory pth_allrec, passing one trial at a time to pipeline in pipeline.py

 if recording_index is not 'all', pipeline_init.py chooses only the recording matching value of recording_index, based on the sorted list of all recordings matching recdates, fly, trial pattern in pth_allrec

 this is convenient because recording_index can be assigned SLURM_ARRAY_TASK_ID in a bash script (e.g. mcp.sbatch), 
 which will run the pipeline on multiple recordings in parallel as a job array on O2 

 for example, the line SBATCH --array=[1-30] will run up to 30 jobs (or as many as resources will allow) in parallel for recordings (date_fly_trial) with recording_index 1-30  

 pipeline.py includes these options: 
 --background subtraction line-by-line (to remove stimulus bleedthrough), 
 --option to temporally smooth the movie before registration (can help if very noisy)
 --motion correction (with caiman NormCorre)
 --denoising (using deepcad), 
 --source extraction (using caiman cNMF)
 ------extraction can operate on 4d xyzt data (planar_extraction = False), or 3d data xyt (planar_extraction = True), where extraction operates on each z plane of the 4d data independently
 ------extraction includes the option to operate on a rectangular subset of the full FOV ('regionex') 
 ------if multiple regionex are provided, the extraction part of the pipeline loops over these   
 ------the extraction part of the pipeline also includes the option to loop over all possible combinations of any subset of extraction parameters, defined in map2params.py
 ------to do this, set index_extraction_param_set to a negative value, and all param combinations up to that index are looped over 
 ------if index_extraction_param_set is positive, only that param set index is run (if 'default', onlt the default param set is run) 
 
 the denoising requires motion corrected input tif, and the extraction requires either the motion correction output tif, or the denoising output tif (depending on whether use_denoised is true of false)

 input to pipeline are the tif files output by ScanImage (precision is int16, not uint16), dimensions are tzyx
 metadata is read from these raw tif files in read_save_metadata.py

 some output files of this pipeline are saved as uint16 (not int16), since the data is nonnegative after processing
 in all stages of the pipeline. int16 or uint16 data is converted to float32 when read in, then operated on

 if regionex is not ['fullfov'], interactive plots prompt user to define a cuboid or rectangular subset of the FOV on which extraction is run 

 do_cropping_session = True will skip everything but this interactive FOV selection for all entries in regionex (and all recordings), but must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, to provide input files for cropping  

 do_cropping_session = True is convenient to cycle through many recordings that have been motion corrected (and optionally denoised), but have not been extracted, and you want to run the extraction on all of them without interruption in a separate job after the cropping session 
 
 the matlab part of the pipeline operates on any/all regionex for any recording 

 if a rectangle or cuboid cannot well separate brain regions that you want separated in later analysis, the matlab part of the pipeline gives the option to further sebset/subdivide any regionex with free drawn rois (we don't do that here because caiman cannot operate on irregularly shaped FOV)

 so, here, region extraction is meant to separately run extraction on regions requiring different extraction params, and/or to run the extraction faster (ie if all extraction_regions amount to less data than the full fov)  

 then, analysis of more precisely defined brain regions is done in the matlab part of the pipeline, where regions can be further split into arbitrary 2d, 3d, or 4d shapes

 since the denoising part of the pipeline requires very different resources on O2, there are 3 bash scripts for the pipeline, one for motion correction (mcp.sbatch, called from conda env caiman), one for denoising (dnp.sbatch, called from conda env deepcadrt), and one for extraction (exp.sbatch, called from conda env caiman) 

 all 3 bash scripts call pipeline_init.py. 

 the pipeline also exists as a jupyter notebook (pipeline_nb.ipynb)
 it is mostly the same but the fov selection plots use different packages, 
 and it uses fewer loops and is less automated 
 BUT, i've been unable to get the denoising working in the ipynb version of the pipeline on O2 (it does work on google colab)

please have a backup of your data outside of the paths this pipeline operates on (path_storage and scratch )
especially if you are using do_copyfiles to automate file transfer to and from O2, 

do_copyfiles may not work well for large transfers (judging by the wording on the O2 website), but for this pipeline, i've had no problems 
 
do_copyfiles occurs inside pipeline_init.py for two reasons:
        1. to ensure everything is the same for the copying and the analysis (ie to ensure the right files get copied)
        2. since slurm arrays are used, it is simpler to copy inside the parallel job

denoising folder is separate from data folder because it can get big (if multiple epochs are used to denoise)

 Once a job dependency fails due to the termination state of a preceding job, the dependent job will never be run, even if the preceding job is requeued and has a different termination state in a subsequent execution.

there are a few spots in the pipeline built to accommodate carl's old project, they are flagged with carls_old_project==1, and in some cases have their own functions (which are named with suffix 'carls_old_project') 

 #########

 the recommended workflow is:

        1. run job array mcp.sbatch to motion correct recordings in parallel (automated)
        2. run job array dnp.sbatch to denoise the same batch of recordings in parallel (automated) - depending on how many recordings in pth_allrec, may need to make recording_index = 'all' to loop in series (not parallel) because of limited GPU resources 
        3. using ineractive job on O2 (visual studio), run pipeline_init.py with do_cropping_session=1, looping over all values in regionex and all recordings in the same batch, letting user define all sub-FOV (interactive)
        4. using job array exp.sbatch, run extraction on all values in regionex for same batch of recordings, optionally using the motion-corrected and denoised or just motion-corrected data (automated)
        5. use matlab pipeline for further analysis using the output of this python pipeline 

############

INSTALLING THINGS

 before running register and extract, caiman and a few other packages need to be installed; to do that, log into O2 compute cluster and run these commands from your home folder 

            srun -p interactive --pty -t 3:00:00 -c 5 --mem=10G bash 
            module purge
            module load miniconda3/4.10.3
            source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
            mamba create -n caiman -c conda-forge caiman
            conda activate caiman
            pip install scanimage-tiff-reader
            pip install mat73
            pip install natsort


 before running denoise, deepcad and torch (and a few other packages) need to be installed; to do that, run these commands on O2 from your home folder 
 
            srun -p interactive --pty -t 4:00:00 -c 15 --mem=50G bash 
            module purge
            module load miniconda3/4.10.3
            source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
            mamba create -n deepcadrt python=3.9
            conda activate deepcadrt
            conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia
            
            pip install deepcad
            pip install mat73
            pip install matplotlib 
            pip install natsort
            pip install scanimage-tiff-reader

if running dnp.sbatch is failing because cuda is not available or torch was not properly installed, you can try this alternative installation for deepcad (which doesn't use conda), and instead of running dnp.sbatch, run dnp2.sbatch

        module purge
        module load gcc/9.2.0 python/3.9.14 cuda/11.7
        virtualenv deepcadrt2
        source deepcadrt2/bin/activate
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
        pip install deepcad
        pip install mat73
        pip install matplotlib
        pip install natsort
        pip install scanimage-tiff-reader

the packages installed with pip while the conda env is active are here 
/home/caw846/.conda/envs/caiman/lib/python3.10/site-packages

if any conda command above is taking too long or not working, you can try substituting "mamba" for "conda"

deepcad repo https://github.com/cabooster/DeepCAD-RT
caiman repo https://github.com/flatironinstitute/CaImAn/tree/main


to use VS Code on O2 (to debug on O2, or to do_cropping_session), you'll be promted to fill out several fields
most of them are intuitive, except for two fields at the bottom
here's the values i use for these two fields for caiman registration or extraction (or just do_cropping session)

Additional modules to be preloaded:
        python/3.10.11 miniconda3/4.10.3

Custom Environment (drag text area to enlarge):
        source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
        conda activate caiman

I leave slurm custom arguments blank 

i have been unable to open the vs code app on o2 when loading the deepcad environment, i think because of a python version conflict


on local machine, used mamba to install caiman, it's licated here 
/Users/wienecke/mambaforge/envs/caiman/lib/python3.10/site-packages/caiman


###### matlab for python ######

to run everything through the same pipeline, install the matlab for python engine, which let's you call matlab functions from within python files (i do this so all analysis goes through the same pipeline, which happens to have a python entrypoint including file selection, copying, renaming, and setting parameters, )

be sure to pip install the correct matlabengine version for the matlab version on O2 that the pip installer finds by default (which appears to be the newest matlab version on O2, which is 2023a, not 2023b, and which corresponds to matlabengine==9.14.3, which is not the latest matlabengine

start an interactive session, then module load the python version you intend to use first, this pipeline uses 3.10 (never tested other versions)

matlabengine will fail to install in the default directory because you don't have write permission there, so the installer will automatically try installing in your home folder, within hidden folder .locals . . . it should work, and if it works, there will be two new folders in ~/.local/lib/python3.10/site-packages, one called matlab and one called matlabengine-9.14.3.dist-info

move both folders into a path you want the pipeline to find . . . for example, you can move them into a virtual environment a conda environment that the pipeline uses . . . below are the commands to move them into the caiman conda environment 

srun -p interactive --pty -t 3:00:00 -c 5 --mem=10G bash
module purge
python/3.10.11
pip install matlabengine==9.14.3
mv ~/.local/lib/python3.10/site-packages/matlab ~/.conda/envs/caiman/lib/python3.10/site-packages
mv ~/.local/lib/python3.10/site-packages/matlabengine-9.14.3.dist-info ~/.conda/envs/caiman/lib/python3.10/site-packages

that should be all you need to do, but here are some more comments

the docs say to put the matlabengine installation path in LD_LIBRARY_PATH in .bashrc if the matlab app is not in the default location . . . its O2 location does not match what the docs report to be defualt, but i've found matlab engine works without doing this, but i'm documenting it here in case somebody needs it, you just open your hidden .bashrc file and put the export line as the last line (you have to reopen your terminal session for the change to take effect)

cd ~
nano .bashrc
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/n/app/matlab/2023a-v2/bin/glnxa64

in case it's useful to know about install failures, initially i tried pip install with the wrong matlabengine version, which fails, and i also tried running setup.py directly, like this
        cd /n/app/matlab/2023a-v2/extern/engines/python
        python3 setup.py build --build-base=“/home/caw846” install --prefix="/home/caw846/.conda/envs/caiman/lib/python3.10/site-packages/matlab23a”
various versions of this approach failed, some actually installed, but would error when using the code


#######240217 wilson lab group folder shared libraries 

https://stackoverflow.com/questions/77474450/using-conda-environment-at-a-specific-directory
conda config --append envs_dirs /n/data1/hms/neurobio/wilson/miniforge3/envs
CONDA_ALWAYS_COPY=1 mamba env create -f env1.yaml -p /shared/conda_envs/env1

if you're using -f it's conda env create, if not using -f then it's just conda create 

##INSTALL MINIFORGE

srun --pty -p interactive -t 0-1:00 --mem=5G bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh
told it not to modify any config files 

##INSTALL CAIMAN

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

##INSTALL DEEPCAD

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

##INSTALL SCOPA
cd /n/data1/hms/neurobio/wilson
git clone https://github.com/wienecke/scopa.git

if you want to step through 3rd party libraries (like deepcad, if you installed with pip install deepcad) during debugging in VS code, do this 

add this line to file launch.json, which is in hidden folder .vscode 
        "justMyCode": false,



####GPU

# gpu_to_use=a100:1,vram:80G  #fastest on gpu_quad (double precision)
# gpu_to_use=teslaV100s:1,vram:32G #lowest vram on on gpu_quad (double precision)
# gpu_to_use=a100:1,vram:40G #fastest on gpu_requeue (here 40G, but 80G also available) (unnamed precision)
# gpu_to_use=rtx6000:1,vram:24G #2nd-lowest vram on gpu_requeue (single precision)
# gpu_to_use=teslaM40:1,vram:12G #lowest vram on gpu_requeue (probably double precision)
# gpu_to_use=teslaV100:1,vram:16G #fastest on gpu partition (double precision)
# gpu_to_use=teslaM40:1,vram:12G #2nd fastest on gpu partition (also 24G) (double precision)



# gpu_to_use=teslaM40:1,vram:12G #lowest vram on gpu_requeue (probably double precision)

TeslaM40 roughly 1:45 min per epoch, so budget at least 10 hours

GPU ID:  0 | Tesla M40 24GB | Memory: 22940 MB
PyTorch version:  2.0.1+cu117

{'overlap_factor': 0.8, 'datasets_path': '/n/scratch/users/c/caw846/denoising//20230627_1_1_all', 'n_epochs': 5, 'fmap': 16, 'output_dir': './results', 'pth_dir': '/n/scratch/users/c/caw846/denoising//20230627_1_1_all', 'onnx_dir': './onnx', 'batch_size': 1, 'patch_t': 102, 'patch_x': 120, 'patch_y': 120, 'gap_y': 23, 'gap_x': 23, 'gap_t': 20, 'lr': 5e-05, 'b1': 0.5, 'b2': 0.9, 'GPU': '0', 'ngpu': 1, 'num_workers': 0, 'scale_factor': 1, 'train_datasets_size': 10000, 'select_img_num': 10000000000.0, 'test_datasize': 400, 'visualize_images_per_epoch': False, 'save_test_images_per_epoch': True, 'colab_display': True, 'result_display': ''}

Training:
[Epoch 1/5] [Batch 10260/10260] [Total loss: 19478.05, L1 Loss: 91.50, L2 Loss: 38864.61] [ETA: 6:39:06] [Time cost: 5977s]   
Testing:
TEST TIME HAS NOT BEEN TESTED YET  

Nodes: 1
Cores per node: 4
CPU Utilized: 06:09:00
CPU Efficiency: 25.62% of 1-00:00:12 core-walltime
Job Wall-clock time: 06:00:03
Memory Utilized: 8.01 GB
Memory Efficiency: 40.07% of 20.00 GB


# gpu_to_use=rtx6000:1,vram:24G #2nd-lowest vram on gpu_requeue (single precision)

rtx6000 roughly 40 min training per epoch, 25 min testing per epoch, so budget at least 6 hours

GPU accessiable. Use GPU for computation.
GPU ID:  0 | Quadro RTX 6000 | Memory: 22691 MB
PyTorch version:  2.0.1+cu117

{'overlap_factor': 0.8, 'datasets_path': '/n/scratch/users/c/caw846/denoising//20230627_1_1_all', 'n_epochs': 5, 'fmap': 16, 'output_dir': './results', 'pth_dir': '/n/scratch/users/c/caw846/denoising//20230627_1_1_all', 'onnx_dir': './onnx', 'batch_size': 1, 'patch_t': 102, 'patch_x': 120, 'patch_y': 120, 'gap_y': 23, 'gap_x': 23, 'gap_t': 20, 'lr': 5e-05, 'b1': 0.5, 'b2': 0.9, 'GPU': '0', 'ngpu': 1, 'num_workers': 0, 'scale_factor': 1, 'train_datasets_size': 10000, 'select_img_num': 10000000000.0, 'test_datasize': 400, 'visualize_images_per_epoch': False, 'save_test_images_per_epoch': True, 'colab_display': True, 'result_display': ''}

Training: 3.5 hours for 5 epochs
[Epoch 1/5] [Batch 10260/10260] [Total loss: 30611.76, L1 Loss: 129.44, L2 Loss: 61094.08] [ETA: 2:19:46] [Time cost: 2162 s]   

Testing: 2 hours for 5 epochs
[Model 1/1, E_05_Iter_10260.pth] [Stack 1/15, 20230627_1_1_0_3047_140_256_uint16_.tif] [Patch 2086/2086] [Time Cost: 101 s] [ETA: 0 s]      

Nodes: 1
Cores per node: 4
CPU Utilized: 04:21:00
CPU Efficiency: 26.69% of 16:18:04 core-walltime
Job Wall-clock time: 04:04:31
Memory Utilized: 8.63 GB
Memory Efficiency: 43.17% of 20.00 GB
