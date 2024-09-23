# H.264 Core Transform

## Literature Review
H.264 Core Transform is a scaled approximation of the 4x4 Discrete Cosine Transform (DCT) termed as an 4x4 Integer Transforn.

Consider a 4x4 two-dimensional forward DCT (FDCT) of a block X:
<p style="text-align:center;">Y = A.X.A<sup>T</sup></p>

Here,
Y -> Matrix of coefficients
X -> Matrix of samples
A -> 4x4 transform matrix


```math
A = \begin{bmatrix}a\\b\\a\\c\a\\c\\-a\\-b\a\\-c\\-a\\b\a\\-b\\a\\-c\end{bmatrix}
``` 
