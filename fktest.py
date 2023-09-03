
import sys
from parse_command_line import parse_command_line_denoise


env_path = sys.path

[pth_in, pth_out, pth_denoising, pth_denoised, fn_prefix, dims] = parse_command_line_denoise(pth_in = "", pth_out = "", 
                    pth_denoising = "", pth_denoised = "", 
                    fn_prefix = "", dims = [])

print(pth_in)
print(pth_out)
print(pth_denoising)
print(pth_denoised)
print(fn_prefix)
print(dims)

print("leaving fktest.py")