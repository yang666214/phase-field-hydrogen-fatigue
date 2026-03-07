# phase-field-hydrogen-fatigue

# Predicting High-Cycle Fatigue under Hydrogen Embrittlement with a Coupled Phase-Field–Diffusion Model

This repository provides the source code and example input files accompanying the paper:

**Predicting High-Cycle Fatigue under Hydrogen Embrittlement with a Coupled Phase-Field–Diffusion Model**

## Overview

Hydrogen embrittlement can significantly accelerate fatigue crack growth in metallic components exposed to cyclic loading and hydrogen-rich environments. This repository provides an open-source implementation of a coupled phase-field–diffusion framework for predicting hydrogen-assisted fatigue crack propagation.

The framework explicitly accounts for:

- hydrogen pre-charging
- stress-assisted hydrogen diffusion
- hydrogen-dependent degradation of fracture toughness
- cycle-block acceleration for high-cycle fatigue
- cycle-to-time mapping to preserve loading-frequency effects
- enhanced transport along fully cracked regions through a damage-activated artificial diffusivity strategy

The implementation is designed to support efficient and reproducible simulations of hydrogen-assisted fatigue crack growth in metallic materials.

## Main features

- Coupled phase-field, mechanics, and hydrogen diffusion framework
- Explicit treatment of hydrogen pre-charging before fatigue loading
- Fracture toughness degradation as a function of local hydrogen concentration
- Efficient high-cycle fatigue simulation using cycle blocks
- Explicit mapping between fatigue cycles and physical diffusion time
- Artificial diffusivity strategy to mimic rapid hydrogen transport along newly formed crack surfaces
- Modular and scalable structure suitable for further multiphysics extensions

## Physical model

The formulation couples:

1. **Mechanical equilibrium**
2. **Phase-field fracture evolution**
3. **Hydrogen diffusion with stress coupling**
4. **Fatigue damage accumulation**

Hydrogen-assisted fatigue degradation is introduced through a hydrogen-dependent fracture toughness function and a fatigue degradation function. In the high-cycle regime, fatigue evolution is advanced in blocks of cycles, while hydrogen diffusion is solved in physical time through a consistent cycle-to-time mapping.

This strategy enables efficient simulations without losing the frequency dependence of hydrogen transport.

## Numerical capabilities

The framework can reproduce key phenomena associated with hydrogen-assisted fatigue, including:

- accelerated crack growth under hydrogen exposure
- effects of hydrogen pre-charging history
- influence of loading frequency on crack growth
- effect of fatigue threshold and degradation exponent
- influence of hydrogen damage coefficient and segregation free energy
- complex crack interactions in multi-crack configurations
