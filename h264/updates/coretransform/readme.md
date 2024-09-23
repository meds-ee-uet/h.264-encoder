# H.264 Core Transform

## Literature Review
H.264 Core Transform is a scaled approximation of the 4x4 Discrete Cosine Transform (DCT) termed as a 4x4 Integer Transform.

Consider a 4x4 two-dimensional forward DCT (FDCT) of a block X:

<p align="center">Y = A.X.A<sup>T</sup></p>

Here:
- **Y** -> Matrix of coefficients
- **X** -> Matrix of samples
- **A** -> 4x4 transform matrix

The transform matrix **A** is defined as:

$$
A = \begin{bmatrix}
a & a & a & a \\
b & c & -c & -b \\
a & -a & -a & a \\
c & -b & b & -c
\end{bmatrix}
$$

Where:

$$
a = \frac{1}{2}
$$

$$
b = \sqrt{\frac{1}{2}} \cos{\frac{\pi}{8}} = 0.6532 \ldots
$$

$$
c = \sqrt{\frac{1}{2}} \cos{\frac{3\pi}{8}} = 0.2706 \ldots
$$

### Forming Cf Matrix

Since core transform is scaled approximation of the DCT, multiplying each coefficient by 2.5 and rounding-off we get:

<p align="center">Y = C.X.C<sup>T</sup></p>

Here:

$$
a \times 2.5 \approx \frac{1}{2} \times 2.5 = 1.25 \approx 1
$$

$$
b \times 2.5 \approx \sqrt{\frac{1}{2}} \cos{\frac{\pi}{8}} \times 2.5 = 0.6532 \times 2.5 = 1.633 \approx 2
$$

$$
c \times 2.5 \approx \sqrt{\frac{1}{2}} \cos{\frac{3\pi}{8}} \times 2.5 = 0.2706 \times 2.5 = 0.6765 \approx 1
$$

Thus, the transform matrix becomes

$$
C = \begin{bmatrix}
1 & 1 & 1 & 1 \\
2 & 1 & -1 & -2 \\
1 & -1 & -1 & 1 \\
1 & -2 & 2 & -1
\end{bmatrix}
$$

This approximation is chosen as a trade-off between computational simplicity and compression performance.
