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
a & b & c & d \\
e & f & g & h \\
i & j & k & l \\
m & n & o & p
\end{bmatrix}
$$
