## H.264 Encoder

The project is divided into 3 parts.

1. **Main Code:** H.264 Encoding module converted from becattles's implementation: [hardh264](https://github.com/bcattle/hardh264).
2. **Inter Prediction**: Module for H.264 standard interprediction.
3. **Data Handling**: It contains a state machine for handling the data input to the h264 encoding module.

## Build and Simulate

### Input video 
Before go to build and simulation, put the raw input video file in the top directory. 
The name and extension of input video file is like: `sample_int.yuv`.

- Drive [link](https://drive.google.com/drive/u/1/folders/1O5z4o965emAxBTRa2YZkY7xVmks2e8HU) for example input video file.
- [Website](https://media.xiph.org/video/derf/) for input video file. 

### Main H.264 Encoder

Goto top directory and run the command

``` make all ```

