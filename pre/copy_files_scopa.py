from pathlib import Path
import time
import shutil
import os



def copy_files_scopa(do_copyfiles, do_register, do_denoise, do_stitch, do_extract, do_crop, do_analysis, 
                     pth_read, pth_md, pth_daq, pth_ftvid, pth_croplim, pth_hires, pth_fldr_copydest_prefix, fldr, 
                     folder_with_all_recordings_on_storage_and_compute_filesystems):


    pp = Path(fldr).parts #split path
    split_index = pp.index(folder_with_all_recordings_on_storage_and_compute_filesystems) + 1
    pth_dest_suffix = os.path.join(*pp[split_index:]) #join to make suffix

    pth_fldr_copydest = pth_fldr_copydest_prefix + pth_dest_suffix
    if pth_fldr_copydest[-1] == '/': 
        pth_fldr_copydest = pth_fldr_copydest[:-1]
    if fldr[-1] != '/': 
        fldr = fldr + '/'

    if do_copyfiles==1: #copy from storage server to O2 (unless do_denoise, since that only uses files in O2 denoising folder, whcih is not copied in or out of O2)
        
        if 0:#do_denoise:
            print("\n\n\nnot copying anything because do_denoise is true, and they use files in denoising folder")
        else:

            Path(pth_fldr_copydest).mkdir(parents=True, exist_ok=True)
            
            if pth_daq and do_analysis:
                print("\n\n\ncopying this file: \n" + pth_daq + "\ninto this directory: \n" + pth_fldr_copydest)
                shutil.copy2(pth_daq, pth_fldr_copydest)
                time.sleep(5) 

            if pth_ftvid and do_register or do_analysis: #do at beginning (or end)
                pth_fldr_copydest_ftv = pth_fldr_copydest + '/FicTracData' #this one requires a subfolder
                Path(pth_fldr_copydest_ftv).mkdir(parents=True, exist_ok=True)
                print("\n\n\ncopying this file: \n" + pth_ftvid + "\ninto this directory: \n" + pth_fldr_copydest_ftv)
                shutil.copy2(pth_ftvid, pth_fldr_copydest_ftv)
                time.sleep(5) 

            if pth_hires and do_analysis:
                print("\n\n\ncopying this file: \n" + pth_hires + "\ninto this directory: \n" + pth_fldr_copydest)
                shutil.copy2(pth_hires, pth_fldr_copydest)
                time.sleep(5) 
            
            if do_extract or do_crop or do_analysis:
                if pth_croplim:
                    for pcl in pth_croplim:
                        print("\n\n\ncopying this file: \n" + pcl + "\ninto this directory: \n" + pth_fldr_copydest)
                        shutil.copy2(pcl, pth_fldr_copydest)
                        time.sleep(5) 
                else:
                    print("there are no croplim files to copy from storage path into compute path, \
                          \nyou will be prompted to create them in interactive mode; \
                          \nyou cannot run extract in batch mode without creating or loading a croplim file, \
                          \nunless your regionex is 'fullfov'")
            
            if pth_md:
                print("\n\n\ncopying this file: \n" + pth_md + "\ninto this directory: \n" + pth_fldr_copydest)
                shutil.copy2(pth_md, pth_fldr_copydest)
                time.sleep(5) 
            
            print("\n\n\ncopying this file: \n" + pth_read + "\ninto this directory: \n" + pth_fldr_copydest)
            shutil.copy2(pth_read, pth_fldr_copydest) #do this last since it's the only big file, i think it helps the small ones finish copying on transfer partition
            time.sleep(5) 
            


    elif do_copyfiles==2: #copy, from O2 to storage server (any new filename, or same filename with different edit time)
        
        if do_denoise:
            print("\n\n\nnot copying anything out because do_denoise is true, and they use files in denoising folder")
        else:
            print("\n\n\ncopying anything new from the O2 folder: \n" + fldr + "\ninto the storage server folder: \n" + pth_fldr_copydest)

            fldr_name = os.path.basename(os.path.abspath(fldr))
            for pth_src_tmp in Path(fldr).glob('**/*'):  #this will copy hidden files too
                pth_src = str(pth_src_tmp)
                if os.path.isfile(pth_src): #only files, no directories (will create parent dirs if necessary below)
                    pp = Path(pth_src).parts #split path
                    split_index = pp.index(fldr_name) + 1 #find index to split source and destination (in case it's within a subdir)
                    pth_dest_suffix = os.path.join(*pp[split_index:]) #join to make suffix
                    pth_dest = pth_fldr_copydest + '/' + pth_dest_suffix #append suffix to source path
                    os.makedirs(os.path.dirname(pth_dest), exist_ok=True) #in case it's within a subdir, create any missing parent dir, if they don't exist  
                    if (not os.path.exists(pth_dest)) or (os.path.exists(pth_dest) and abs(os.stat(pth_src).st_mtime - os.stat(pth_dest).st_mtime) > 1) :
                        try:
                            shutil.copy2(pth_src, pth_dest)
                        except shutil.SameFileError:
                            print("same file error error occurred while copying this file: \n" + pth_src + "\nto this path \n:" + pth_dest)
                        except PermissionError:
                            print("permission error occurred while copying this file: \n" + pth_src + "\nto this path \n:" + pth_dest)
                        except:
                            print("Unknown error occurred while copying this file: \n" + pth_src + "\nto this path \n:" + pth_dest)

