# Attitude Determination

This section covers the attitude determination and control system (ADCS).

## Author

[Jonathan Cochran](https://github.com/ionzzu)

## Description

- The attitude for the satellite is estimated by using the B-dot algorithm and considering polar orbits
- This algorithm modifies the frame of reference and adds the rotating matrix functions
- Over one rotation around the earth, the angular position, velocity, and acceleration of the satellite are determined
- After these values are known, magnetorquer coils can be induced to adjust the attitude to the desired values

## Results

![ang_acc_stacked](../docs/ref/att_determination/ang_acc_stacked.png)
![ang_vel_stacked](../docs/ref/att_determination/ang_vel_stacked.png)
![bdot_output_summary](../docs/ref/att_determination/bdot_output_summary.png)

## Base Environment Requirements

- MATLAB R2017b or higher

- Aerospace Toolbox

## Installation

1. Clone the repository

2. Run bdot_control_algo.m

## Acknowledgment

Framework for B-dot algorithm derived from github.com/catnip-evergreen/bdot-algo
