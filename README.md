# hackster-programmer

This is the repository for the Python programming script which is used to interact with the "Hackster" hardware security and hardware development platform. 

I also include the hackster-fw compiled uf2 image which runs on the RP2040 programmer (and is what this Python script interacts with).

## Instructions to install

1. Proceed to https://github.com/YosysHQ/oss-cad-suite-build/releases/tag/2026-01-04 and download the appropriate archive for your OS (e.g., oss-cad-suite-linux-x64...tgz for 64-bit Linux). 
2. Extract it to a suitable location on your PC.
3. Navigate to the extracted folder and then `source` the `environment` script to set up your environment variables. For example, on Linux:
   ```bash
   $ cd path/to/oss-cad-suite-build-2026-01-04
   $ source environment
   ```
4. You'll need to source this environment script each time you open a new terminal to work with the Hackster programmer.
5. Clone this repository to a sensible location on your PC:
```bash
$ git clone https://github.com/kiwih/hackster-programmer.git hackster-programmer
```
6. Navigate to the `hackster-programmer` folder:
```bash
$ cd hackster-programmer
```
7. You're now ready to go.