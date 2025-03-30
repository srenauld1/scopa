

in=peaks(128); %// Define input signal
in=squeeze(fuk(1:128,1:128,:,3));

sz1=size(in,1); 
sh1=[1:sz1]-ceil(median([1:sz1]));
sz2=size(in,2); 
sh2=[1:sz2]-ceil(median([1:sz2]));

H=fftshift(fft2(in)); %// Compute 2D Fourier Transform
x0=-20; %// Define shifts
y0=-20;

%// Define shift in frequency domain
[xF,yF] = meshgrid(sh2,sh1);

%// Perform the shift
H=H.*exp(-1i*2*pi .* (-x0 * xF / sz2 - y0 * yF / sz1));
H=H.*exp(-1i*2*pi.*(xF*x0+yF*y0)/sz1);

%// Find the inverse Fourier Transform
IF_image=ifft2(ifftshift(H));

%// Show the images
figure;
subplot(1,2,1);
imshow(in);
subplot(1,2,2);
imshow(real(IF_image));