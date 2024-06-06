
import numpy as np
import caiman as cm


def make_registration_template(pth_tif_read, pth_prefix, md, register_in_2d, halfwidth_window_bgsub, len_window_smooth_t_mcp, fn_prefix, pth_denoising, denoise_volume, carls_old_project, cluster_backend, use_cluster, makeplots):


    dims, T = cm.base.movies.get_file_size(fname, var_name_hdf5=var_name_hdf5)
    Ts = np.arange(T)[subidx].shape[0]
    
    use_different_number_frames_in_2d_and_3d_templates = 0 #WILSONLAB, CFRW, 240218, 0 TO MAKE 2D AND 3D HAVE SAME TEMPLATE NUM FRAMES (SET TO 1 FOR ORIGINAL)
    if use_different_number_frames_in_2d_and_3d_templates:
        step = Ts // 10 if is3D else Ts // 50 #this was the original line
    else:
        goal_frames_in_template = 50
        step = Ts // goal_frames_in_template 
    
    corrected_slicer = slice(subidx.start, subidx.stop, step + 1)
    m = cm.load(fname, var_name_hdf5=var_name_hdf5, subindices=corrected_slicer)

    if len(m.shape) < 3:
        m = cm.load(fname, var_name_hdf5=var_name_hdf5)
        m = m[corrected_slicer]
        logging.warning("Your original file was saved as a single page " +
                        "file. Consider saving it in multiple smaller files" +
                        "with size smaller than 4GB (if it is a .tif file)")

    if is3D:
        m = m[:, indices[0], indices[1], indices[2]]
    else:
        m = m[:, indices[0], indices[1]]

    if template is None:
        if gSig_filt is not None:
            m = cm.movie(
                np.array([high_pass_filter_space(m_, gSig_filt) for m_ in m]))
        if is3D:     
            # TODO - motion_correct_3d needs to be implemented in movies.py
            template = caiman.motion_correction.bin_median_3d(m) # motion_correct_3d has not been implemented yet - instead initialize to just median image
#            template = caiman.motion_correction.bin_median_3d(
#                    m.motion_correct_3d(max_shifts[2], max_shifts[1], max_shifts[0], template=None)[0])
        else:
            if not m.flags['WRITEABLE']:
                m = m.copy()
            register_template = 0 #WILSONLAB, CFRW, 240218, SWITCH OFF TEMPLATE REGISTER, IT CAN MAKE A BAD TEMPLATE FOR A NOISY MOVIE 
            if register_template:
                template = caiman.motion_correction.bin_median(
                        m.motion_correct(max_shifts[1], max_shifts[0], template=None)[0])
            else:
                template = caiman.motion_correction.bin_median(m)
