#include <cstdio>
#include <cstdlib>
#include <cstdint>

static FILE* out_file = nullptr;

extern "C" {

// Initialize the output file
void dpi_open_file(const char* filename) {
    out_file = fopen(filename, "wb");
    if (!out_file) {
        perror("Failed to open file");
        exit(1);
    }
}

// Write a single byte
void dpi_write_byte(uint8_t c) {
    if (out_file) {
        fwrite(&c, 1, 1, out_file);
    }
}

// Close the file
void dpi_close_file() {
    if (out_file) {
        fclose(out_file);
        out_file = nullptr;
    }
}

}
