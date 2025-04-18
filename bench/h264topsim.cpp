#include "Vh264topsim.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;                // Current simulation time
double sc_time_stamp() { return main_time; } // Required by Verilator tracing

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Instantiate the DUT
    Vh264topsim* top = new Vh264topsim;

    // VCD dump enable flag
    bool vcd_enabled = false;
    for (int i = 0; i < argc; ++i) {
        if (std::string(argv[i]) == "+vcd=1") {
            vcd_enabled = true;
        }
    }

    VerilatedVcdC* tfp = nullptr;
    if (vcd_enabled) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);              // Trace depth
        tfp->open("dump.vcd");
    }

    // Initial clock state
    top->clk2 = 0;

    const int MAX_CYCLES = 1000000000;

    // Main simulation loop
    for (int cycle = 0; cycle < MAX_CYCLES && !Verilated::gotFinish(); ++cycle) {
        // Clock low
        top->clk2 = 0;
        top->eval();
        if (vcd_enabled) tfp->dump(main_time++);
        
        // Clock high
        top->clk2 = 1;
        top->eval();
        if (vcd_enabled) tfp->dump(main_time++);
    }

    // Finish and cleanup
    top->final();
    if (vcd_enabled) {
        tfp->close();
        delete tfp;
    }
    delete top;

    return 0;
}
