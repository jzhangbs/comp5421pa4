# COMP5421 Project 4
This project implements _Photometric Stereo via Expectation Maximization_ by Tai-Pang Wu and Chi-Keung Tang.

## Algorithm description
### Uniform Resampling
First we need to quantize all the possible directions. We use the vertices of the upper half of a subdivided icosphere at level 4. We use code from [here](https://www.mathworks.com/matlabcentral/fileexchange/50105-icosphere).

Then we interpolate the images with light directions as the quantized ones. The original light directions each has a nearest quantized direction and some quantized directions are nearest directions of multiple original directions. For this quantized direction, the set `V` contains these multiple original directions. Now we can interpolate the images by the formula.

### Find Denominator Image
Find denominator image by the following steps.
1. Calculate the intensity percentile of each position over all the images.
2. For each image, count the number of pixel with percentile > 70%, `k_L`.
3. For each image, calculate the average percentile of the pixels with percentile > 70%, `r`. And calculate the percetile of each `r`.
4. Discard all the images that the percentile of `r` > 90%.
5. Choose the image with the largest `k_L` from the remaining images.

### Calculate Initial Normal
Divide each image by the denominator image to get ratio images. For each position in each ratio image, we have this equation.

![Imgur](https://i.imgur.com/4fOBS5sm.png)

In total we have `N-1` equations for each pixel. Solve the system by SVD.

### Refine the Normal by Graph Cut
Again we quantize the possible directions by the upper half of a icosphere at level 5. And we use them as labels and want to assign these finite labels to each pixel so that the energy is minimized.

![Imgur](https://i.imgur.com/8jxN78Fm.png)

### Visualization
We can get the surface plot by the following steps.
1. Vertically flip the normal map.
2. Convert normal to gradient `(-N(1)/N(3), -N(2)/N(3))`.
3. Convert gradient to slant and tilt by [this tool](http://www.peterkovesi.com/matlabfns/#shapelet).
4. Convert slant and tilt to depth map.
5. Plot depth map by Matlab `surf` function.

## Result
The initial normal map, refined normal map, refined surface and refined surface with texture.

![Imgur](https://i.imgur.com/OUCTkhVt.jpg)
![Imgur](https://i.imgur.com/Zc8PkBst.jpg)
![Imgur](https://i.imgur.com/pZZj98bt.jpg)
![Imgur](https://i.imgur.com/VZNFl98t.jpg)

![Imgur](https://i.imgur.com/KZrU0K6t.jpg)
![Imgur](https://i.imgur.com/SJYR2OVt.jpg)
![Imgur](https://i.imgur.com/gI6B0t8t.jpg)
![Imgur](https://i.imgur.com/L02fgIrt.jpg)

![Imgur](https://i.imgur.com/4uvRT6Lt.jpg)
![Imgur](https://i.imgur.com/LluCDaot.jpg)
![Imgur](https://i.imgur.com/Fi6aNxrt.jpg)
![Imgur](https://i.imgur.com/GqqUjltt.jpg)

![Imgur](https://i.imgur.com/wUX62zKt.jpg)
![Imgur](https://i.imgur.com/WMD6zdmt.jpg)
![Imgur](https://i.imgur.com/sOtHPGMt.jpg)
![Imgur](https://i.imgur.com/9Y0M69At.jpg)

![Imgur](https://i.imgur.com/2DN6g7ht.jpg)
![Imgur](https://i.imgur.com/320IbKlt.jpg)
![Imgur](https://i.imgur.com/a4urii2t.jpg)
![Imgur](https://i.imgur.com/Sb6fWkIt.jpg)

![Imgur](https://i.imgur.com/5A4MuGut.jpg)
![Imgur](https://i.imgur.com/Lp1put0t.jpg)
![Imgur](https://i.imgur.com/19Rmopot.jpg)
![Imgur](https://i.imgur.com/lSb8Cs4t.jpg)

![Imgur](https://i.imgur.com/l9UjVQNt.jpg)
![Imgur](https://i.imgur.com/QYYJGBst.jpg)
![Imgur](https://i.imgur.com/QJ3THimt.jpg)
![Imgur](https://i.imgur.com/j31NzOMt.jpg)

![Imgur](https://i.imgur.com/SY2BD8nt.jpg)
![Imgur](https://i.imgur.com/hyQlG6Yt.jpg)
![Imgur](https://i.imgur.com/WzsnV6Nt.jpg)
![Imgur](https://i.imgur.com/jim0vgvt.jpg)
