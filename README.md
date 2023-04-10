# S.AP.P.H.O. Project
## Scattering-based APparatus for Portable Haematological analysis via Optics

### Information
This repository is the main repository for the [SAPPHO project](http://microengineering.iem.ihu.gr/curprojects.html). The design, fabrication, calibration, and testing of a non-invasive, portable Mie scattering-based blood quality sensor are presented in this project.The prototype device currently consists of a 1500x1-pixel photodiode array sensor, a 650 nm laser diode, and a novel case designed to facilitate a variety of optical experiments. Furthermore, this project presents the findings of several in-vivo and in-vitro experiments performed with either the current device or previous prototypes of the device. The SAPPHO project began with our thesis ([Scattering measurements with the Beaglebone microcomputer for portable biomedical sensors](http://microengineering.iem.ihu.gr/repo/2022MichailidouBantis.pdf)\), but its roots can be traced back to the work of [Stratos Gkagkanis](http://microengineering.iem.ihu.gr/repo/2019Gkagkanis.pdf) ([`@StratosGK`](https://github.com/StratosGK)), [Konstantinos Karakostas](http://ikee.lib.auth.gr/record/305140?ln=el) ([`@konkarak`](https://www.linkedin.com/in/konkarak/)), [Ilias Kavoukis](http://microengineering.iem.ihu.gr/repo/2020Kavoukis.pdf) ([`@iliaskavoukis`](https://www.linkedin.com/in/iliaskavoukis/)), and [Dr. Michail E. Kiziroglou](https://spiral.imperial.ac.uk/bitstream/10044/1/48460/4/17_SPIE_asPublished.pdf) ([`@m.kiziroglou`](https://www.imperial.ac.uk/people/m.kiziroglou)).

### Directories
* `./debian-mirror`
  - In case the official Beagleboard website stops distributing the Debian image (`bone-debian-8.7-iot-armhf-2017-03-19-4gb.img.xz`) used in our thesis, this directory contains links to mirrors.
* `./sappho-analysis`
  - The `sappho-analysis` directory contains scripts for analyzing samples taken with the Toshiba TCD1103GFG PDA or the AMS TSL1401CL PDA.
* `./sappho-cad` 
  - This directory houses `.stl` files for the 3D-printed case as well as other peripherals.
* `./sappho-docs`
  - The `sappho-docs` directory contains pdf documents such as our thesis and its presentation, our publications, and the TeX source code for some legal documents required for the project.
* `./sappho-pcb`
  - The directory `sappho-pcb` contains the files required for printing and/or editing the project's PCB 
* `./sappho-pda`
  - This directory contains the source code required for using the Toshiba TCD1103GFG PDA sensor in conjunction with the Beaglebone Black Rev. C microcomputer, as well as some installation scripts. This code has been forked from StratosGK's "SGK_PDA" driver for the AMS TSL1401CL PDA. Please copy this directory under the directory `/home/debian/`.
  
### Installation & Building
* TODO

### Future plans
- [ ] Support the Arduino UNO R4
- [ ] Support the Espressif ESP32D
- [ ] Support the Raspberry Pi RP2040
- [ ] Support an STM32 microcontroller

### Current Primary Contributors
* [@bandisast](https://github.com/bandisast)
* [@MariaMich](https://github.com/MariaMich)
