% TEMPCTRLPARAMETERS initializes a set of bus objects and parameters in the MATLAB base workspace 

% Bus object: MonitoringSignalsType 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'setpoint';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'actual';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

MonitoringSignalsType = Simulink.Bus;
MonitoringSignalsType.HeaderFile = '';
MonitoringSignalsType.Description = '';
MonitoringSignalsType.DataScope = 'Auto';
MonitoringSignalsType.Alignment = -1;
MonitoringSignalsType.Elements = elems;
clear elems;

% Parameters of the temperature control models

A = ...
  [-0.0831290733245929 0.00831290733245929;
   0.0831290733245929 -0.011083876443279054];

C_1 = 31.5774;

C_2 = 315.774;

D = 3.1037611591959409;

K_12 = 2.625;

K_2e = 0.875;

K_2e0 = 0.55;

K_2e1 = 1.2;

Kp = 50;

T_0 = 65.888206809004316;

Td = 5;

Tn = 200;

Tv = 1;

b = [1; 0];

c = [0 0.0031668218409368724];

d = 0;

theta_0 = 20;

% Time-scaling factor of the simulated heater block (2 = plant heats up twice as fast).
% Applied as plantSpeedup*A and plantSpeedup*b in TempCtrlSysPT2; DC gain is unchanged.
plantSpeedup = 4;

% Default setpoint [degC] of TempCtrl, used while the Setpoint input is 0 (unconnected)
SetpointDefault = 37;
