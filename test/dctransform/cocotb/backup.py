# Define the matrix C for the transform
C = np.array([
    [1,  1,  1,  1],
    [2,  1, -1, -2],
    [1, -1, -1,  1],
    [1, -2,  2, -1]
])

def core_transform_4x4(block):
    """
    Apply the core transform to a 4x4 block.
    
    The transform is defined as Y = C . X . Ct,
    where C is the transformation matrix and X is the input block.
    """
    # Ensure block is a 4x4 numpy array
    block = np.array(block).reshape(4, 4)
    
    # Apply the core transform
    Y = C @ block @ C.T
    
    return Y

def apply_core_transform_to_image(image):
    """
    Apply the core transform to the entire image block by block.
    """
    height, width = image.shape
    
    # Calculate new dimensions to ensure they are multiples of 4
    new_height = (height + 3) // 4 * 4
    new_width = (width + 3) // 4 * 4
    
    # Create a padded image to hold the new dimensions
    padded_image = np.zeros((new_height, new_width), dtype=image.dtype)
    padded_image[:height, :width] = image
    
    # Create an output image of the same size as the padded image
    transformed_image = np.zeros_like(padded_image)
    
    for row in range(0, new_height, 4):
        for col in range(0, new_width, 4):
            # Extract 4x4 block from the padded image
            block = padded_image[row:row+4, col:col+4]
            
            # Apply the core transform to the block
            transformed_block = core_transform_4x4(block)
            
            # Place the transformed block back into the transformed image
            transformed_image[row:row+4, col:col+4] = transformed_block
    
    # Crop the transformed image back to the original size
    return transformed_image[:height, :width]

def coretransform_py(image_path):
    print("Applying core transform through python...")
    # Load the image and convert it to grayscale
    img = Image.open(image_path).convert('L')
    image = np.array(img)
    print("Loaded image succesfuly!")
    
    # Apply the core transform to the image
    transformed_image = apply_core_transform_to_image(image)
    
    # Convert the transformed image back to a PIL image and save it
    transformed_img = Image.fromarray(transformed_image.astype(np.uint8))
    transformed_img.save('../images/output_py.png')

    print("Transformation complete. Output saved as 'transformed_image_bw.png'.")


#////////////////////////////

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from PIL import Image, ImageOps
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
    img = Image.open(image_path)
    img = img.convert('L')  # Convert image to grayscale
    pixels = list(img.getdata())
    print(f"Image size is {img.size}")
    width, height = img.size
    pixel_array = [pixels[i * width:(i + 1) * width] for i in range(height)]
    return pixel_array



@cocotb.test()
async def test_core_transform(dut):
    cocotb.start_soon(clock_gen(dut))

    await reset_sequence(dut)


    # Load and convert the image to grayscale
    image_path = '../images/input.png'
    pixels = image_to_grayscale_pixels(image_path)
    print("Succesfully converted input.png into pixels")

    width = 512
    height = 512

    # Initialize an array to store the reconstructed grayscale image
    reconstructed_image = np.zeros((height, width), dtype=np.uint8)
    original_image = np.zeros((height, width), dtype=np.uint8)

    for row in range(0, height, 4):
        for col in range(0, width, 4):
            # Extract 4x4 block of grayscale pixels
            pixel_block = []
            for i in range(4):
                for j in range(4):
                    pixel_block.append(pixels[row + i][col + j])

            # Send the pixel block to the DUT
            for i in range(4):
                xxin = (
                    0 | (pixel_block[i*4+3] & 0xFF) << 27 |
                    0 | (pixel_block[i*4+2] & 0xFF) << 18 |
                    0 | (pixel_block[i*4+1] & 0xFF) << 9 |
                    0 | (pixel_block[i*4] & 0xFF)
                )

                #await RisingEdge(dut.CLK)
                while not dut.READY.value:
                    await RisingEdge(dut.CLK)

                dut.ENABLE.value = 1
                dut.XXIN.value = xxin
                await RisingEdge(dut.CLK)

            dut.ENABLE.value = 0

            #await RisingEdge(dut.CLK)
            while not dut.VALID.value:
                await RisingEdge(dut.CLK)

            # Store the output pixels directly in the correct positions
            for i in range(16):
                output_pixel = int(dut.YNOUT.value)
                reconstructed_image[row+REVERSE_ZIGZAG_ORDER[i][0],col+REVERSE_ZIGZAG_ORDER[i][1]] = output_pixel
                await RisingEdge(dut.CLK)
        print(f"Succesfully processed Row #{row} to #{row+4}")

    # Convert the reconstructed array back into an image
    reconstructed_img = Image.fromarray(reconstructed_image, mode='L')
    reconstructed_img.save('../images/output_sv.png')
    original_img = Image.fromarray(original_image, mode='L')
    original_img.save('../images/input_sv.png')


    print("Test completed and black and white image reconstructed as 'reconstructed_image_bw.png'")