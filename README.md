<div align="center">


<a href="https://rob.pages.gitlab.kuleuven.be/crospi/"><img src="./logo.png" alt="crospi Logo" width="750" /></a>


Supports only ROS2 humble and later versions


[![Humble Build](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-humble.yml/badge.svg?branch=main)](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-humble.yml?branch=main)
[![Iron Build](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-iron.yml/badge.svg?branch=main)](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-iron.yml?branch=main)
[![Jazzy Build](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-jazzy.yml/badge.svg?branch=main)](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-jazzy.yml?branch=main)
[![Kilted Build](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-kilted.yml/badge.svg?branch=main)](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-kilted.yml?branch=main)
[![Rolling Build](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-rolling.yml/badge.svg?branch=main)](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-rolling.yml?branch=main)
[![Lyrical Build](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-lyrical.yml/badge.svg?branch=main)](https://github.com/Robotics-Research-Group-KUL/crospi/actions/workflows/build-and-test-ros2-lyrical.yml?branch=main)

<div align="left">

## Summary

Crospi is a ROS2 pipeline that allows developers to easily define reactive robot behaviors through high-level constraint-based task specifications. It represents a new generation of our software stack, building upon earlier frameworks such as [iTaSC](https://orocos.org/itasc.html) and [eTaSL](https://etasl.pages.gitlab.kuleuven.be/), and consolidating mature capabilities that were previously developed within [Orocos-based systems](https://rob.pages.gitlab.kuleuven.be/legacy_etasl_website/). By leveraging real-time sensor-driven control, Crospi enables robots to continuously adapt to uncertainty and environmental changes, moving beyond traditional sense–plan–act paradigms toward fully reactive control strategies. Unlike motion-planning frameworks such as MoveIt, which focus on the sense-plan-act paradigm, producing collision-free trajectories, Crospi emphasizes continuous feedback and constraint satisfaction during execution, enabling truly reactive, sensor-driven behaviors. Crospi also provides smart tools that enable developers to create libraries that can be easily shared with other developers and orchestrated into complex applications.


## Documentation

Ready to get started? Our [documentation website](https://rob.pages.gitlab.kuleuven.be/crospi/) has everything you need:

- **Getting Started** — installation, running examples, and your first application.
- **Tutorials** — step-by-step guides for developing task specifications, skills, and applications.
- **API Reference** — detailed documentation for developers.
- **Glossary** — definitions of all key terms.

Whether you are writing your first eTaSL task specification or building a multi-skill robotic application, the documentation walks you through every layer of the Crospi stack.


## Citation

If you use Crospi in your research, please cite:

```
@misc{iregui2026crospi,
    author = {Iregui, Santiago and Ulloa, Federico and Aertbeli\"{e}n, Erwin},
    title = {Crospi: an open-source Constraint-based Reactive and Orchestrated Sensor-driven PIpeline for robot control},
    howpublished = "\url{https://github.com/Robotics-Research-Group-KUL/crospi}",
    year = {2026}
}
```

## License and acknowledgements

Published under the [GNU LESSER GENERAL PUBLIC LICENSE](LICENSE) Version 3, 29 June 2007.

<a href="https://aiprism.eu/"><img src="./Ai-Prism_Logo_Horizontal.png" alt="AI-PRISM Logo" width="150" /></a>
This work was funded by the European Union’s Horizon 2020 research and innovation program 
under the grant agreement No. <a href="https://cordis.europa.eu/project/id/101058589">101058589</a> ( <a href="https://aiprism.eu/">AI-Prism</a>) 


## Authors
<p float="left">
<a href="https://www.kuleuven.be/english/kuleuven/">
    <img src="./logo_kuleuven.png" alt="KU Leuven Logo" width="150"/>
</a>
<a href="https://www.mech.kuleuven.be/en/research/ram">
    <img src="./logo_RAM.png" alt="RAM Logo" width="110" />
</a>
<a href="https://www.flandersmake.be/en">
    <img src="./FM_LOGO_whitebg.png" alt="RAM Logo" width="400" />
</a>
</p>

(c) 2025, KU Leuven, Department of Mechanical Engineering, ROB-Group:

- [Santiago Iregui Rincon](https://www.kuleuven.be/wieiswie/en/person/00125886)
- [Erwin Aertbeliën](https://www.kuleuven.be/wieiswie/en/person/00002405)
- [Federico Ulloa Rios](https://www.kuleuven.be/wieiswie/en/person/00141400)
