# phase-field-hydrogen-fatigue

A Felino-based implementation of coupled phase-field and hydrogen-diffusion models for hydrogen-assisted fatigue crack initiation and growth.

This repository provides the input files, example cases, and post-processing scripts associated with our published studies on hydrogen-assisted fatigue phase-field modelling.

## Overview

Hydrogen embrittlement can significantly accelerate fatigue crack initiation and fatigue crack growth in metallic materials under cyclic loading. This project implements a coupled phase-field-diffusion framework for simulating hydrogen-assisted fatigue damage, crack initiation, and crack propagation.

The current implementation is developed based on **Felino**, a MOOSE-based phase-field fatigue application.

Felino repository:  
https://github.com/DanielChou0916/felino

Therefore, this repository is **not a standalone finite-element solver**. Please install **MOOSE** and **Felino** first, and then run the hydrogen-assisted fatigue phase-field codes provided here.

## Main functions

The implemented framework supports:

- coupled phase-field fracture and hydrogen diffusion
- hydrogen pre-charging
- stress-assisted hydrogen diffusion
- hydrogen-dependent degradation of fracture resistance
- fatigue damage accumulation under cyclic loading
- cycle-block acceleration for high-cycle fatigue simulations
- cycle-to-time mapping for loading-frequency effects
- hydrogen-assisted crack initiation and propagation
- fatigue crack growth under gaseous hydrogen pressure
- anisotropic hydrogen-assisted fatigue crack growth
- welded pipeline simulations with base metal, weld metal, and heat-affected zone regions
- residual-stress-informed hydrogen-assisted fatigue simulations
- surface roughness and initial defect sensitivity studies
- two-dimensional and three-dimensional simulations

## Repository structure

The repository is organized by paper. Each main folder corresponds to one published study, and the related input files and example cases are provided in the `examples/` folder.

```text
phase-field-hydrogen-fatigue/
│
├── 01_IJF_2026/
│   └── examples/
│
├── 02_EJMS_2026/
│   └── examples/
│
├── 03_JMRT_2026/
│   └── examples/
│
└── README.md
```

## Installation

### 1. Install MOOSE

Please first install MOOSE by following the official installation guide:

https://mooseframework.inl.gov/getting_started/installation/

After installation, activate the MOOSE environment:

```bash
conda activate moose
```

### 2. Install Felino

Clone and compile Felino:

```bash
cd ~/projects
git clone https://github.com/DanielChou0916/felino.git
cd felino
make -j4
```

The executable `felino-opt` will be used to run the input files in this repository.

### 3. Clone this repository

```bash
cd ~/projects
git clone https://github.com/yang666214/phase-field-hydrogen-fatigue.git
cd phase-field-hydrogen-fatigue
```

## Usage

After MOOSE and Felino are installed, enter the folder of the corresponding paper and run the selected input file using `felino-opt`.

For a serial run:

```bash
~/projects/felino/felino-opt -i input_file.i
```

For a parallel run:

```bash
mpiexec -n 8 ~/projects/felino/felino-opt -i input_file.i
```

For example:

```bash
cd ~/projects/phase-field-hydrogen-fatigue/01_IJF_2026/inputs
mpiexec -n 8 ~/projects/felino/felino-opt -i example.i
```

To find all available input files:

```bash
find . -name "*.i"
```

Simulation outputs can be visualized using ParaView.

## Associated publications

This project is associated with the following papers.

### 1. High-cycle fatigue under hydrogen embrittlement

**Predicting high-cycle fatigue under hydrogen embrittlement with a coupled phase-field-diffusion model**  
*International Journal of Fatigue*, 210, 109674, 2026.  
https://doi.org/10.1016/j.ijfatigue.2026.109674

### 2. Pipeline steels under gaseous hydrogen pressure

**Hydrogen-assisted fatigue crack growth of pipeline steels under gaseous hydrogen pressure: A unified anisotropic phase-field model**  
*European Journal of Mechanics - A/Solids*, 118, 106106, 2026.  
https://doi.org/10.1016/j.euromechsol.2026.106106

### 3. Welded pipeline steels

**A multiphysics phase-field-diffusion framework for hydrogen-assisted fatigue crack initiation and growth in welded pipeline steels**  
*Journal of Materials Research and Technology*, 42, 5457-5474, 2026.  
https://doi.org/10.1016/j.jmrt.2026.04.131

## Citation

If you use this repository, the implemented models, or the example files in your research, please cite the relevant papers above.

Recommended citation entries:

```bibtex
@article{Yang2026IJF,
  title   = {Predicting high-cycle fatigue under hydrogen embrittlement with a coupled phase-field-diffusion model},
  author  = {Yang, Shiyuan and others},
  journal = {International Journal of Fatigue},
  volume  = {210},
  pages   = {109674},
  year    = {2026},
  doi     = {10.1016/j.ijfatigue.2026.109674}
}
```

```bibtex
@article{Yang2026EJMS,
  title   = {Hydrogen-assisted fatigue crack growth of pipeline steels under gaseous hydrogen pressure: A unified anisotropic phase-field model},
  author  = {Yang, Shiyuan and others},
  journal = {European Journal of Mechanics - A/Solids},
  volume  = {118},
  pages   = {106106},
  year    = {2026},
  doi     = {10.1016/j.euromechsol.2026.106106}
}
```

```bibtex
@article{Yang2026JMRT,
  title   = {A multiphysics phase-field-diffusion framework for hydrogen-assisted fatigue crack initiation and growth in welded pipeline steels},
  author  = {Yang, Shiyuan and others},
  journal = {Journal of Materials Research and Technology},
  volume  = {42},
  pages   = {5457--5474},
  year    = {2026},
  doi     = {10.1016/j.jmrt.2026.04.131}
}
```

Please check the final author lists from the published papers when preparing formal bibliographies.

## Contact

Questions, discussions, and collaborations are very welcome.

Please contact:

**Shiyuan Yang**  
Email: syyang214000@gmail.com
