 scopa
 
 updated by carl wienecke 231201


 this is the first part of the analysis pipeline for volumetric (xyzt) 2p imaging with behavior and visual stimuli

 this first part of the pipeline is in python (entry point pipeline_init.py), and it operates on the imaging data only (not on behavior or stimulus data) 

 the second part of the pipeline is in matlab (entry point is cx_analysis.m), and operates on the output of this first part (imaging data) and also behavior and stimulus data

 there are a few basic plots for results in function caiman_plots_all (in file vis.py)

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
 ------extraction includes the option to operate on a rectangular subset of the full FOV ('region_extraction') 
 ------if multiple region_extraction are provided, the extraction part of the pipeline loops over these   
 ------the extraction part of the pipeline also includes the option to loop over all possible combinations of any subset of extraction parameters, defined in map2params.py
 ------to do this, set index_extraction_param_set to a negative value, and all param combinations up to that index are looped over 
 ------if index_extraction_param_set is positive, only that param set index is run (if 'default', onlt the default param set is run) 
 
 the denoising requires motion corrected input tif, and the extraction requires either the motion correction output tif, or the denoising output tif (depending on whether use_denoised is true of false)

 input to pipeline are the tif files output by ScanImage (precision is int16, not uint16), dimensions are tzyx
 metadata is read from these raw tif files in read_save_metadata.py

 some output files of this pipeline are saved as uint16 (not int16), since the data is nonnegative after processing
 in all stages of the pipeline. int16 or uint16 data is converted to float32 when read in, then operated on

 if region_extraction is not ['fullfov'], interactive plots prompt user to define a cuboid or rectangular subset of the FOV on which extraction is run 

 do_cropping_session = True will skip everything but this interactive FOV selection for all entries in region_extraction (and all recordings), but must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, to provide input files for cropping  

 do_cropping_session = True is convenient to cycle through many recordings that have been motion corrected (and optionally denoised), but have not been extracted, and you want to run the extraction on all of them without interruption in a separate job after the cropping session 
 
 the matlab part of the pipeline operates on any/all region_extraction for any recording 

 if a rectangle or cuboid cannot well separate brain regions that you want separated in later analysis, the matlab part of the pipeline gives the option to further sebset/subdivide any region_extraction with free drawn rois (we don't do that here because caiman cannot operate on irregularly shaped FOV)

 so, here, region extraction is meant to separately run extraction on regions requiring different extraction params, and/or to run the extraction faster (ie if all extraction_regions amount to less data than the full fov)  

 then, analysis of more precisely defined brain regions is done in the matlab part of the pipeline, where regions can be further split into arbitrary 2d, 3d, or 4d shapes

 since the denoising part of the pipeline requires very different resources on O2, there are 3 bash scripts for the pipeline, one for motion correction (mcp.sbatch, called from conda env caiman), one for denoising (dnp.sbatch, called from conda env deepcadrt), and one for extraction (exp.sbatch, called from conda env caiman) 

 all 3 bash scripts call pipeline_init.py. 

 the pipeline also exists as a jupyter notebook (pipeline_nb.ipynb)
 it is mostly the same but the fov selection plots use different packages, 
 and it uses fewer loops and is less automated 
 BUT, i've been unable to get the denoising working in the ipynb version of the pipeline on O2 (it does work on google colab)


 #########

 the recommended workflow is:

        1. run job array mcp.sbatch to motion correct recordings in parallel (automated)
        2. run job array dnp.sbatch to denoise the same batch of recordings in parallel (automated) - depending on how many recordings in pth_allrec, may need to make recording_index = 'all' to loop in series (not parallel) because of limited GPU resources 
        3. using ineractive job on O2 (visual studio), run pipeline_init.py with do_cropping_session=1, looping over all values in region_extraction and all recordings in the same batch, letting user define all sub-FOV (interactive)
        4. using job array exp.sbatch, run extraction on all values in region_extraction for same batch of recordings, optionally using the motion-corrected and denoised or just motion-corrected data (automated)
        5. use matlab pipeline for further analysis using the output of this python pipeline 

############

INSTALLING THINGS

 before running register and extract, caiman and a few other packages need to be installed; to do that, log into O2 compute cluster and run these commands from your home folder (you probably could use a lot less than -c 15 --mem=50G in the first command, but who cares)

            srun -p interactive --pty -t 3:00:00 -c 15 --mem=50G bash 
            module purge
            module load miniconda3/4.10.3
            source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
            conda create -n caiman -c conda-forge caiman
            conda activate caiman
            pip install scanimage-tiff-reader
            pip install mat73
            pip install natsort


 before running denoise, deepcad and torch (and a few other packages) need to be installed; to do that, run these commands on O2 from your home folder 
 
            srun -p interactive --pty -t 4:00:00 -c 15 --mem=50G bash 
            module purge
            module load miniconda3/4.10.3
            source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
            conda create -n deepcadrt python=3.9
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
        pip install scanimage-tiff-reader
        pip install natsort

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


