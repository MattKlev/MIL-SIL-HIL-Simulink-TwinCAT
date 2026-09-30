%[text] # MIL → SIL → HIL with Simulink and TwinCAT
%[text] One controller model, designed once in Simulink® and taken **unchanged** through three test stages with TwinCAT 3. Each stage swaps only what surrounds the controller.
%[text:tableOfContents]{"heading":"Contents"}
%[text:table]
%[text] | Stage | Controller runs in | Plant runs in | Coupling |
%[text] | --- | --- | --- | --- |
%[text] | MIL | Simulink (model reference) | Simulink | Signal lines |
%[text] | SIL | TwinCAT usermode runtime (generated TcCOM module) | Simulink | FMU (TE1421) |
%[text] | HIL | TwinCAT real-time on the controller IPC | TwinCAT real-time on a second IPC | EtherCAT (TE1111) |
%[text:table]
%[text] Run this guide section by section from the `simulink` folder. Nothing has to be compiled: the TwinCAT modules and the FMU ship precompiled.
%[text] The models are derived from the TE1400 sample *Basic Concepts: Generating TwinCAT Classes from Simulink Models* by Beckhoff Automation GmbH & Co. KG.
addpath(fullfile(pwd,'helpers')) % functions that open TwinCAT solutions from MATLAB and arrange the windows
%%
%[text] ## 1. Model-in-the-loop
%[text] Simulate controller and plant together in Simulink. The scope in the model shows the setpoint and the actual temperature.
open_system('TempCtrlClosedLoop')
open_system('TempCtrlClosedLoop/Scope')
set_param('TempCtrlClosedLoop','SimulationCommand','start')
%%
%[text] ## 2. Get the TwinCAT modules
%[text] SIL and HIL run `TempCtrl` and `TempCtrlSysPT2` as compiled TwinCAT modules. Install the precompiled modules once on each TwinCAT PC. Building them yourself is only needed after you change a model.
%%
%[text] ### Install the precompiled modules
%[text] `twincat/modules` holds a self-extracting TMX archive per module, generated with TE1400. Running the two archives installs the modules into the TwinCAT repository of this PC, where the TwinCAT projects expect them. Run them once, then continue with step 3.
modules = fullfile('..','twincat','modules');
system(['"' fullfile(modules,'TempCtrl.exe') '" /noprompt /console'])
system(['"' fullfile(modules,'TempCtrlSysPT2.exe') '" /noprompt /console'])
%%
%[text] ### Build the modules yourself
%[text] Use this after you change a model. It requires TE1400 Target for Simulink®. Close the TwinCAT projects in XAE before running this section. It opens both models next to MATLAB and builds them; the build output appears in the MATLAB Command Window.
open_system('TempCtrl')
open_system('TempCtrlSysPT2')
PlaceWindow('MATLAB','left')
PlaceWindow('TempCtrl','topright')
PlaceWindow('TempCtrlSysPT2','bottomright')
slbuild('TempCtrl')
slbuild('TempCtrlSysPT2')
%[text] Changing the controller is therefore one step: edit the model and build it. The build compiles the module, installs it on this PC, updates the archive in `twincat/modules`, and reloads the module in the TwinCAT projects through the TwinCAT Automation Interface (`helpers/UpdateTwinCatProjects.m`). No manual step in TwinCAT is needed.
%%
%[text] ## 3. Software-in-the-loop
%[text] `TcSimRuntimeTempCtrl.fmu` wraps a TwinCAT usermode runtime. Simulink steps the plant, the runtime executes the generated `TempCtrl` module, and the FMU keeps both synchronized. The FMU waits for a TwinCAT configuration before the simulation advances.
%[text] Run the section below. It opens the SIL model below this guide and the TwinCAT solution in XAE on the right, with the block diagram of the `TempCtrl` object. Then:
%[text] 1. Start the simulation in Simulink. It pauses at start while the runtime waits for activation.
%[text] 2. In XAE, choose the runtime started by the FMU from the target system list.
%[text] 3. Select **Activate Configuration** and switch to Run Mode.
%[text] 4. Watch the scope in Simulink and the block diagram in XAE. The response matches the MIL result. \
open_system('TempCtrlClosedLoop_SIL')
dte = OpenTwinCatSolution('sil/TwinCAT SIL.sln');
ShowBlockDiagram(dte,'TempCtrl')
PlaceWindow('MATLAB','topleft')
PlaceWindow('TempCtrlClosedLoop_SIL','bottomleft')
PlaceWindow(dte,'right')
%[text] To configure the simulation runtime and export the FMU yourself, see the TE1421 documentation and video tutorials:
%[text] - [Workflow for carrying out a simulation](https://infosys.beckhoff.com/content/1033/te1421_tc3_simulation_runtime_for_fmi/16998941323.html?id=7241220697704420840)
%[text] - [Video: Configuration of the simulation runtime](https://www.beckhoff.com/en-us/company/news/multimedia-tutorial-twincat-3-simulation-runtime-for-fmi-configuration-of-the-simulation-runtime.html)
%[text] - [Video: Using the simulation runtime in Simulink®](https://www.beckhoff.com/en-us/company/news/multimedia-tutorial-twincat-3-simulation-runtime-for-fmi-using-the-simulation-runtime-in-simulink-r.html) \
%%
%[text] ## 4. Hardware-in-the-loop
%[text] Two industrial PCs are connected by a single EtherCAT cable; no terminals are needed. The controller IPC runs `TempCtrl` as EtherCAT master. The simulation IPC runs `TempCtrlSysPT2` and uses TE1111 EtherCAT Simulation to behave like the real terminals. The controller cannot tell the difference from real hardware.
%[text:table]
%[text] | Emulated terminal | Signal |
%[text] | --- | --- |
%[text] | EK1100 | Coupler |
%[text] | EL3312, channel 1 | Temperature from plant to controller |
%[text] | EL2002, channel 1 | Heater on/off from controller to plant |
%[text:table]
%[text] Run the section below. It opens both TwinCAT solutions in XAE side by side, the simulation project on the left and the master project on the right, each with the block diagram of its module. Then:
%[text] 1. In the simulation project, choose the simulation IPC as target, assign its network adapter to *Device 1 (EtherCAT Simulation)*, and activate the configuration.
%[text] 2. In the master project, choose the controller IPC as target, assign its network adapter to *Device 1 (EtherCAT)*, and activate the configuration.
%[text] 3. Check that the EtherCAT master reaches OP state, then observe `MonitoringSignals` of the `TempCtrl` object. \
sim = OpenTwinCatSolution('hil-sim/TwinCAT Project EC Sim.sln');
master = OpenTwinCatSolution('hil-master/TwinCAT Project EC Master.sln');
ShowBlockDiagram(sim,'TempCtrlSysPT2')
ShowBlockDiagram(master,'TempCtrl')
PlaceWindow(sim,'left')
PlaceWindow(master,'right')
%[text] To set up the EtherCAT simulation for your own I/O configuration, see the [TE1111 EtherCAT Simulation quickstart](https://infosys.beckhoff.com/content/1033/te1111_ethercat_simulation/577128203.html?id=5636951470982116002).
%%
%[text] ## Summary
%[text] The controller model is never modified between stages. Only its surroundings change: a simulated plant in Simulink, the same plant coupled through an FMU, and finally the plant behind a simulated EtherCAT network. Differences between the stages therefore point to timing, data types, or I/O configuration rather than to the control algorithm.
%%
%[text] ## Documentation
%[text:table]
%[text] | Product | Used for |
%[text] | --- | --- |
%[text] | [TE1400 TwinCAT 3 Target for Simulink](https://infosys.beckhoff.com/content/1033/te1400_tc3_target_simulink/10811425803.html?id=1931982227502486525) | Generating the TcCOM modules from the Simulink models |
%[text] | [TE1421 TwinCAT 3 Simulation Runtime for FMI](https://infosys.beckhoff.com/content/1033/te1421_tc3_simulation_runtime_for_fmi/index.html?id=2606403756298260215) | SIL: running TwinCAT inside Simulink as an FMU |
%[text] | [TE1111 TwinCAT 3 EtherCAT Simulation](https://infosys.beckhoff.com/content/1033/te1111_ethercat_simulation/index.html?id=438080824056288076) | HIL: emulating the EtherCAT terminals |
%[text:table]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
