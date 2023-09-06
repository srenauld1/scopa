

import numpy as np
import matplotlib.pyplot as plt
import random
from scipy import signal

##########################################################################################################################################

# background subtraction currently cannot be disabled (but would be simple to include the option)
# background subtraction finds, for each line, the contiguous block of pixels with the lowest intensity, then subtracts the mean of that block from the entire line   
# the spectrum before and after background subtraction is saved

##########################################################################################################################################

class bgremover:

    def __init__(self, img, pth_save_prefix, half_wid=12, dimorder='tyx'):
        self.half_wid = half_wid
        self.pth_save_prefix = pth_save_prefix
        if dimorder=='tyx':
            self.img = img
        elif dimorder=='txy':
            self.img = np.transpose(img, (0, 2, 1))

    def draw_patches(self):
        half_wid = self.half_wid
        wid = 2*half_wid
        kernel = np.ones(wid)/wid
        self.meanframe = np.mean(self.img, axis=0)
        bg_ind = []
        for line in self.meanframe:
            tmp = np.convolve(line, kernel, 'valid')
            bg_center = np.argmin(tmp) + half_wid
            bg_ind.append([bg_center-half_wid, bg_center+half_wid])
        self.bg_ind = bg_ind

    def remove_bg(self, offset=0):
        bg_ind = self.bg_ind
        out = self.img.copy()
        for ind in range(out.shape[1]):
            patch = self.img[:, ind, :]
            bg_patch = self.img[:, ind, bg_ind[ind][0]:bg_ind[ind][1]]
            bg = bg_patch.mean(axis=-1)
            patch = patch-bg[None].T
            out[:, ind, :] = patch
        out = out + offset # compensate so that most of the pixels are above 0 (deprecated)
        self.out = out

    def make_plots(self):

        half_wid = self.half_wid
        
        patch_im = np.mean(self.img, axis=0)
        mv = np.max(patch_im)
        for i in range(patch_im.shape[0]):
            patch_im[i, self.bg_ind[i][0]:self.bg_ind[i][1]] = mv
        
        y_len, x_len = self.out.shape[1:3]
        test_y = random.randint(0, y_len-1)
        test_x = random.randint(0, x_len-2*half_wid-1) + half_wid

        test_patch = self.img[:, test_y, test_x-half_wid:test_x+half_wid]
        test = test_patch.mean(-1)
        test = test/test.mean()

        fs = self.img.shape[-1]
        f, Pxx_den = signal.periodogram(test, fs)
        fig, ((ax1, ax2), (ax3, ax4), (ax5, ax6), (ax7, ax8)) = plt.subplots(4, 2)
        ax1.semilogy(f[1:], Pxx_den[1:]) #skip 0 frequency

        test_patch = self.out[:, test_y, test_x-half_wid:test_x+half_wid]
        test = test_patch.mean(-1)
        test = test/test.mean()

        f, Pxx_den = signal.periodogram(test, fs)
        ax2.semilogy(f[1:], Pxx_den[1:]) #skip 0 frequency

        ax3.imshow(self.meanframe)
        ax3.axis('off')
        
        self.meanframe_nobg = np.mean(self.out, axis=0)

        ax4.imshow(self.meanframe_nobg)
        ax4.axis('off')

        ax5.hist(self.img.ravel(), bins=50)
        ax5.set_yscale('log')
        ax6.hist(self.out.ravel(), bins=50)
        ax6.set_yscale('log')
            
        ax7.imshow(patch_im)

        plt.savefig(self.pth_save_prefix + '_bgplots.png')
        plt.close()


