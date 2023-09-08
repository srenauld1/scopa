 scopa
 
 carl wienecke 230902


 this is the first part of the analysis pipeline for volumetric (xyzt) 2p imaging with behavior and visual stimuli (might not be optimaized for single plane xyt analysis)

 this first part of the pipeline is in python (entry point pipeline_init.py), and it operates on the imaging data only (not on behavior or stimulus data) 

 the second part of the pipeline is in matlab (entry point is cx_analysis.m), and operates on the output of this first part (imaging data) and also behavior and stimulus data

 there aren't many plots associated with this first part (they are disabled since the idea is for this first part to run in the background on all recordings, to prepare the data for more interactive analysis in matlab)

 if recording_index = 0, pipeline_init.py cycles through all recordings in directory specified by pth_allrec, passing one trial at a time to pipeline in pipeline.py

 if recording_index is not 0, pipeline_init.py chooses only the recording matching value of recording_index (based on the sorted list of all reocrdings in pth_allrec)

 this is convenient because recording_index can be assigned SLURM_ARRAY_TASK_ID in a bash script (e.g. mcp.sbatch), 
 which will run the pipeline on multiple recordings in parallel as a job array on O2 

 for example, the line SBATCH --array=[1-30] will run up to 30 jobs (or as many as recources allow) in parallel for recordings (date_fly_trial) with recording_index 1-30  

 pipeline.py includes these options: 
 --background subtraction line-by-line (to remove stimulus bleedthrough), 
 --motion correction (with caiman NormCorre)
 --denoising (using deepcad), 
 --source extraction (using caiman cNMF)
 ------extraction can operate on 4d xyzt data (planar_extraction = False), or 3d data xyt (planar_extraction = True), where extraction operates on each z plane of the 4d data independently
 ------extraction includes the option to operate on a rectangular subset of the full FOV ('region_extraction') 
 ------if multiple region_extraction are provided, the extraction part of the pipeline loops over these   
 ------the extraction part of the pipeline also includes the option to loop over all possible combinations of any subset of extraction parameters, defined in map2params.py
 ------to do this, set index_extraction_param_set to a negative value, and all param combinations up to that index are looped over 
 ------if index_extraction_param_set is positive, only that param set index is run (if 'None', onlt the default param set is run) 
 these subroutines can be run at separate times, or all in one sequence for example, motion correction for all files in a directory, then in another job, denoising for all those same files, then extraction
 the denoising requires motion corrected input tif, and the extraction requires either the motion correction output tif, or the denoising output tif (depending on whether use_denoised is true of false)

 input to pipeline are the big tif files output by ScanImage (precision is int16, not uint16), dimensions are tzyx
 metadata is read from these same tif files 

 some output files of this pipeline are saved as uint16 (not int16), since the data is nonnegative after processing
 in all stages of the pipeline, int16 or uint16 data is converted to float32 when read in, then operated on

 the whole pipeline is automated except if region_extraction is not [''], in which case interactive plots prompt user to define a cuboid or rectangular subset of the FOV on which extraction is run 

 do_cropping_session = True will skip everything but this interactive FOV selection for all entries in region_extraction, 
 but must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, to provide input files for cropping 

 do_cropping_session = True is convenient to cycle through many recordings that have been motion corrected (and optionally denoised) 

 at once so then extraction can be run in a separate job on a batch of recordings in pth_allrecs without interruption 
 the matlab part of the pipeline operates on any/all region_extraction for any recording 

 if a rectangle or cuboid cannot well separate brain regions that you want separated in later analysis, the matlab part of the pipeline gives the option to further sebset/subdivide any region_extraction

 so, here, region extraction is meant to separately run extraction on regions requiring different extraction params, and/or to run the extraction faster (ie if all extraction_regions amount to less data than the full fov)  

 then, analysis of more precisely defined brain regions is done in the matlab part of the pipeline, where regions can be further split into arbitrary 2d, 3d, or 4d shapes

 since the denoising part of the pipeline requires very different resources on O2, 
 and I have been unable to easily merge the caiman and deepcad virtual environments because of conflicts (presumably because deepcad is in an older python), 
 there is a bash script for running the denoising part of the pipeline (in caiman environment), and another bash script for running anything but denoising (in deepcadrt environment)

 but both bash scripts call pipeline_init.py, since denoising script is built into the pipeline for convenience
 the pipeline should be run in a virtual environment with caiman installed

 the denoising script is called using os.system to change the virtual environment from caiman to deepcad from within pipeline.py, 
 but after denoising the environment returns to caiman

 the user can run the entire pipeline in one automated job (if region extraction = [''], or if region_extraction FOVs have already been defined for all region_extraction values), 
 but if do_denoising = True, resources for that job should change when transitioning into and out of the denoising part of the pipeline

 but this repo currently does not have a bash script to dynamically change SLURM resources during a job

 the recommended workflow is:
 1. run job array mcp.sbatch to motion correct recordings in parallel (automated)
 2. run job array dnp.sbatch to denoise the same batch of recordings in parallel (automated) - depending on how many recordings in pth_allrec, may need to make recording_index = 0 to loop in sequence (not parallel) because of limited GPU resources 
 3. using ineractive job on O2 (visual studio), run pipeline_init.py, looping over all values in region_extraction and all recordings in the same batch of recordings (by making input params match those in cxp.sbatch and dnp.sbatch), letting user define all sub-FOV (interactive)
 4. using job array exp.sbatch, run extraction on all values in region_extraction for same batch of recordings, optionally using the motion-corrected and denoised or just motion-corrected data (automated)
 5. use matlab pipeline for further analysis using the output of this python pipeline 

 these sbatch files are written to run on requeue-type partitions (using other people's resources), and will automatically requeue if preempted

 before running any of the sbatch files mentioned above, caiman needs to be installed; to do that, log into O2 compute cluster and run these commands (you probably could use a lot less than -c 15 --mem=50G in the first command, but who cares)
 srun -p interactive --pty -t 4:00:00 -c 15 --mem=50G bash 
 module purge
 module load miniconda3/4.10.3
 source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
 mamba create -n caiman -c conda-forge caiman

 after that you also need to run the following commands (to install an extra package in the caiman environment) 
 module load miniconda3/4.10.3
 source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
 conda activate caiman
 pip install scanimage-tiff-reader

 before running denoise.py (from within in dnp.sbatch or directly on command line), deepcad and torch need to be installed; to do that, run these commands on O2
 srun -p interactive --pty -t 4:00:00 -c 15 --mem=50G bash 
 module purge
 module load miniconda3/4.10.3
 source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
 mamba create -n caiman -c conda-forge caiman

 after that you also need to run the following commands (to install a couple extra packages in the deepcad environment) 
 module load miniconda3/4.10.3
 source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
 conda activate deepcadrt
 pip install mat73
 pip install matplotlib 

 if you want to run the pipeline in a jupyter notebook, run pipeline.ipynb
 it is mostly the same but the fov selection plots are trivially different, 
 and it does not loop through recordings and region_extraction (one at a time, since the purpose of the ipynb pipeline is interactivity anyway)   
 as with the .py pipeline, the .ipynb pipeline needs to be run either for denoising or anything but denoising, for the same reasons 
 use the same environment configuration commands listed above for anything but denoising, 
 but for denoising in pipeline.ipynb, i have been unable to get the jupyter notebook to open on O2 (working on that still)