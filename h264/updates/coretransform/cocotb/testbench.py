import cocotb
from cocotb.triggers import RisingEdge, Timer
from PIL import Image
import numpy as np

# Clock generation
async def clock_gen(dut):
    while True:
        dut.CLK.value = 0
        await Timer(10, units='ns')
        dut.CLK.value = 1
        await Timer(10, units='ns')

# Reset sequence
async def reset_sequence(dut):
    await RisingEdge(dut.CLK)
    dut.RESET.value = 0
    dut.ENABLE.value = 0
    await RisingEdge(dut.CLK)
    await RisingEdge(dut.CLK)
    dut.RESET.value = 1

# Reverse Zigzag Order Mapping for a 4x4 matrix
REVERSE_ZIGZAG_ORDER = [(3,3),(3,2),(2,3),(1,3),(2,2),(3,1),(3,0),(2,1),(1,2),(0,3),(0,2),(1,1),(2,0),(1,0),(0,1),(0,0)]

def image_to_grayscale_pixels(image_path):
    img = Image.open(image_path).convert('L')  # Convert image to grayscale
    pixels = list(img.getdata())
    width, height = img.size
    pixel_array = [pixels[i * width:(i + 1) * width] for i in range(height)]
    return pixel_array, width, height

def create_image_from_pixels(pixel_array, image_size, filename):
    """
    Create an image from a 2D array of pixels.
    """
    img = Image.fromarray(np.array(pixel_array, dtype=np.uint8), mode='L')
    img.save(filename)

@cocotb.test()
async def test_core_transform(dut):
    cocotb.start_soon(clock_gen(dut))
    await reset_sequence(dut)

    # Load and convert the image to grayscale
    image_path = '../images/input.png'
    pixels, width, height = image_to_grayscale_pixels(image_path)
    while ((width%4) != 0):
        width -= 1
    while ((height%4) != 0):
        height -= 1
    print(f"Width = {width}; Height = {height}")
    print("Successfully converted input.png into pixels")

    # Initialize lists to store input and output pixels
    input_pixel_array = np.zeros((height, width))
    output_pixel_array = np.zeros((height, width))

    for row in range(0, height, 4):
        for col in range(0, width, 4):
            # Extract 4x4 block of grayscale pixels
            pixel_block = []
            for i in range(4):
                for j in range(4):
                    if row + i < height and col + j < width:
                        pixel_block.append(pixels[row + i][col + j])
                    else:
                        pixel_block.append(0)  # Use 0 for out-of-bound indices

            # Send the pixel block to the DUT and store the input pixels
            for i in range(4):
                xxin = (
                    (pixel_block[i*4+3] & 0xFF) << 27 |
                    (pixel_block[i*4+2] & 0xFF) << 18 |
                    (pixel_block[i*4+1] & 0xFF) << 9 |
                    (pixel_block[i*4] & 0xFF)
                )

                # Store the input pixel block in the array
                for idx in range(4):
                    input_pixel_array[row + i, col + idx] = pixel_block[i*4 + idx]

                while not dut.READY.value:
                    await RisingEdge(dut.CLK)

                dut.ENABLE.value = 1
                dut.XXIN.value = xxin
                await RisingEdge(dut.CLK)

            dut.ENABLE.value = 0

            # Read output pixels from DUT and store them
            while not dut.VALID.value:
                await RisingEdge(dut.CLK)
            
            for i in range(16):
                output_pixel = int(dut.YNOUT.value)
                output_pixel_array[row + REVERSE_ZIGZAG_ORDER[i][0], col + REVERSE_ZIGZAG_ORDER[i][1]] = output_pixel
                await RisingEdge(dut.CLK)

        print(f"Successfully processed Row #{row} to #{row + 4}")
    print("Row processing completed!")

    # Create images from the input and output pixels
    create_image_from_pixels(input_pixel_array, (width, height), '../images/input_image.png')
    create_image_from_pixels(output_pixel_array, (width, height), '../images/output_image.png')

    print("Test completed. Images saved as 'input_image_from_xxin.png' and 'output_image_from_dut.png'")
