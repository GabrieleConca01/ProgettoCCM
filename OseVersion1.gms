
* Files required are:
* OseVersion1 (this file)
* osemosys_dec.gms
* utopia_data.txt
* osemosys_equ.gms
*
* To run this GAMS version of OSeMOSYS on your PC:
* 1. YOU MUST HAVE GAMS VERSION 22.7 OR HIGHER INSTALLED.
* This is because OSeMOSYS has some parameter, variable and equation names
* that exceed 31 characters in length, and GAMS versions prior to 22.7 have
* a limit of 31 characters on the length of such names.
* 2. Ensure that your PATH contains the GAMS Home Folder.
* 3. Place all 4 of the above files in a convenient folder,
* open a Command Prompt window in this folder, and enter:
* gams osemosys.gms
* 4. You should find that you get an optimal value of 29446.861.
* 5. Some results are created in file SelResults.CSV that you can view in Excel.
* OPTIONS
* --storage=1 to enable storage constraints
* --mip=1 to solve the problem as a mixed integer linear program. To be paired with appropriate definition of parameter CapacityOfOneTechnologyUnit
* --scen={base,ren_target,ctax,emicap,nocoal,cost_res} to run the model with different constraints
* --data={baseenergysystem,utopia,renewables} to run the model with different data
$eolcom #
$onmulti
$onrecurse
$if not set scen $setglobal scen base
$if not set data $setglobal data baseenergysystem
$include "Model/osemosys_dec.gms"
* specify Model data
$include "Data/%data%_data.gms"
* perform data computations when needed
$include "Model/compute_data.gms"
* define model equations
$include "Model/osemosys_equ.gms"


* some model options
model osemosys /all/;
option limrow=0, limcol=0, solprint=on;
option mip = copt;
option lp = conopt;

* first, solve the model without any constraints
$ifthen.solvermode set mip
solve osemosys minimizing z using mip;
$else.solvermode
solve osemosys minimizing z using lp;
$endif.solvermode

$include "Model/osemosys_res.gms"
execute_unload 'Results/results_SCENbase_DATA%data%.gdx';

* some scenario flags
$ifthen.scen set ren_target
equation my_RE4_EnergyConstraint(REGION,YEAR);
my_RE4_EnergyConstraint(r,y)..
    %ren_target%/100*(sum(f, AccumulatedAnnualDemand(r,f,y) + SpecifiedAnnualDemand(r,f,y))) =l= TotalREProductionAnnual(r,y);
$setglobal scen "rentarget%ren_target%"
$endif.scen

$ifthen.scen set ctax 
EmissionsPenalty(r,'CO2',y) = %ctax%;
$setglobal scen "ctax%ctax%"
$endif.scen

$ifthen.scen set emicap 
AnnualEmissionLimit(r,'CO2',y)$(ord(y) ge 10) = %emicap%;
$setglobal scen "emicap%emicap%"
$endif.scen

$ifthen.scen set nocoal 
TotalAnnualMaxCapacity(r,'COAL',y) = .5;
$setglobal scen "nocoal"
$endif.scen

$ifthen.scen set cost_res 
CapitalCost(r,t,y)$renewable_tech(t) = %cost_res%/100 * CapitalCost(r,t,y);
$setglobal scen "lowcost%cost_res%"
$endif.scen

* solve the model with the constraints
$ifthen.notbase not %scen%=="base" 

$ifthen.solvermode set mip
solve osemosys minimizing z using mip;
$else.solvermode
solve osemosys minimizing z using lp;
$endif.solvermode

* create results in file SelResults.CSV
$include "Model/osemosys_res.gms"
$include "Model/report.gms"
execute_unload 'Results/results_SCEN%scen%_DATA%data%.gdx';

$endif.notbase
