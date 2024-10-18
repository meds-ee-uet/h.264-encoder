# H.264 Core Transform

## Literature Review
H.264 Core Transform is a scaled approximation of the 4x4 Discrete Cosine Transform (DCT) termed as a 4x4 Integer Transform.

Consider a 4x4 two-dimensional forward DCT (FDCT) of a block X:

**<p align="center">Y = A.X.A<sup>T</sup></p>**

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

**<p align="center">Y = C.X.C<sup>T</sup></p>**

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

## Design Specifications

The module accepts input in the form of **4 packets** of **36 bits** each in **4 clock cycles**, each containing **4 pixels** of **9 bits each** through **READY-VALID Handshake** totalling **16 pixels** in **4 clock cycles** equaling to total number of elements in a **4x4 Input Marix X**.

The standard size of pixels in our H.264 Module is 8 bits, but due processing in prediction module we assume a pixel to be 9 bit as input to H.264 Core Transform module.

The module provides a **14 bit pixel** as **output**. After accepting the input, the module asserts the VALID output signal after **4 clock cycles**. Once VALID output signal is asserted, it will deassert after **16 clock cycles** and provide a **14 bit pixel** as output in each cycle in **reverse zigzag order** which is explained below:

$$
Reverse Zigzag Order = \begin{bmatrix}
16 & 15 & 11 & 10 \\
14 & 12 & 9  & 4  \\
13 & 8  & 5  & 3  \\
7  & 6  & 2  & 1
\end{bmatrix}
$$

### Design: Top-Level Module


### Design: Controller Top-Level


### Design: Controller State Machine Diagram


### Design: Datapath


### Design: Datapath + Controller



## Future Improvements - Timescaled

With approximately the same amount of hardware in the core transform module, **4 pixels** can be generated at output instead of **1 pixel** per clock cycle. This will save total of **12 clock cycles** but this may require more hardware at the destination side.

However, this improvement can be implemented by removing the **4x1 MUX** at the end of datapath as provided in the figure below:

