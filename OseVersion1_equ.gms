$stitle Model equations
*
* OSeMOSYS 2011.07.07 conversion to GAMS by Ken Noble, Noble-Soft Systems - August 2012
* OSeMOSYS 2017.11.08 update by Thorsten Burandt, Konstantin Löffler and Karlo Hainsch, TU Berlin (Workgroup for Infrastructure Policy) - October 2017
*
* OSeMOSYS 2017.11.08
* Main changes to previous version OSeMOSYS_2016_08_01
* Bug fixed in:
* - Equation E1
* Open Source energy Modeling SYStem
*
* 2022.03.28 Fix EBa10_EnergyBalanceEachTS4, fix SI7_SalvageValueStorageAtEndOfPeriod2, fix SV2_SalvageValueAtEndOfPeriod2, add parentheses in conditional expressions where ambiguous, replace = with eq where appropriate, use card of set not already in used, improve storage constraints names, import comments from docs,  y Giacomo Marangoni

* ============================================================================
*


*------------------------------------------------------------------------	
* Objective function       
*------------------------------------------------------------------------

* This equation represents the overall objective of the model. The default
* in OSeMOSYS is to minimise the total system cost, over the entire model
* period.
free variable z;
equation Objective;
Objective..
    z =e= sum((r,y), TotalDiscountedCost(r,y));



*------------------------------------------------------------------------	
* Rate of demand       
*------------------------------------------------------------------------


* The equation below is used to generate the term RateOfDemand, from the
* user-provided data for SpecifiedAnnualDemand and
* SpecifiedDemandProfile. The RateOfDemand is defined for each combination
* of commodity, TimeSlice and Year.
equation EQ_SpecifiedDemand1(REGION,TIMESLICE,FUEL,YEAR);
EQ_SpecifiedDemand1(r,l,f,y)$(SpecifiedAnnualDemand(r,f,y) gt 0)..
    SpecifiedAnnualDemand(r,f,y)*SpecifiedDemandProfile(r,f,l,y) / YearSplit(l,y) =e= RateOfDemand(r,l,f,y);


*------------------------------------------------------------------------	
* Capacity Adequacy A       
*------------------------------------------------------------------------

* Used to first calculate total capacity of each technology for each year
* based on existing capacity from before the model period
* (ResidualCapacity), AccumulatedNewCapacity during the modelling period,
* and NewCapacity installed in each year. It is then ensured that this
* Capacity is sufficient to meet the RateOfTotalActivity in each TimeSlice
* and Year. An additional constraint based on the size, or capacity, of
* each unit of a Technology is included
* (CapacityOfOneTechnologyUnit). This stipulates that the capacity of
* certain Technology can only be a multiple of the user-defined
* CapacityOfOneTechnologyUnit.

* Calculates cumulative new capacity installed over the time horizon
equation CAa1_TotalNewCapacity(REGION,TECHNOLOGY,YEAR);
CAa1_TotalNewCapacity(r,t,y)..
    AccumulatedNewCapacity(r,t,y) =e= 
$ifthen.solvermode set mip
    sum(yy$((y.val-yy.val < OperationalLife(r,t)) AND (y.val-yy.val >= 0)), NewCapacity(r,t,yy))
$else.solvermode 
    AccumulatedNewCapacity(r,t,y-1) * (1 - ContinousDepreciation(r,t)) + NewCapacity(r,t,y)
$endif.solvermode
    ;

equation CAa2_TotalAnnualCapacity(REGION,TECHNOLOGY,YEAR);
CAa2_TotalAnnualCapacity(r,t,y)..
    AccumulatedNewCapacity(r,t,y) + ResidualCapacity(r,t,y) =e= TotalCapacityAnnual(r,t,y);

equation CAa3_TotalActivityOfEachTechnology(YEAR,TECHNOLOGY,TIMESLICE,REGION);
CAa3_TotalActivityOfEachTechnology(y,t,l,r)..
    sum(m, RateOfActivity(r,l,t,m,y)) =e= RateOfTotalActivity(r,l,t,y);

equation CAa4_Constraint_Capacity(REGION,TIMESLICE,TECHNOLOGY,YEAR);
CAa4_Constraint_Capacity(r,l,t,y)..
    RateOfTotalActivity(r,l,t,y) =l= TotalCapacityAnnual(r,t,y) * CapacityFactor(r,t,l,y) * CapacityToActivityUnit(r,t);


* NOTE: OSeMOSYS uses Mixed Integer Programming to solve models that
* define CapacityOfTechnologyUnit. Using this parameter is likely to
* increase the model computation time.
$ifthen.solvermode set mip
equation CAa5_TotalNewCapacity(REGION,TECHNOLOGY,YEAR);
CAa5_TotalNewCapacity(r,t,y)$(CapacityOfOneTechnologyUnit(r,t,y) <> 0)..
    CapacityOfOneTechnologyUnit(r,t,y) * NumberOfNewTechnologyUnits(r,t,y) =e= NewCapacity(r,t,y);
$endif.solvermode



*------------------------------------------------------------------------	
* Capacity Adequacy B       
*------------------------------------------------------------------------

* Ensures that adequate capacity of technologies is present to at least
* meet the average annual demand.

equation CAb1_PlannedMaintenance(REGION,TECHNOLOGY,YEAR);
CAb1_PlannedMaintenance(r,t,y)..
    sum(l, RateOfTotalActivity(r,l,t,y)*YearSplit(l,y)) =l= sum(l,TotalCapacityAnnual(r,t,y)*CapacityFactor(r,t,l,y)*YearSplit(l,y))*AvailabilityFactor(r,t,y)*CapacityToActivityUnit(r,t);



*------------------------------------------------------------------------	
* Energy Balance A       
*------------------------------------------------------------------------

* Ensures that demand for each commodity is met in each TimeSlice.

equation EBa1_RateOfFuelProduction1(REGION,TIMESLICE,FUEL,TECHNOLOGY,MODE_OF_OPERATION,YEAR);
EBa1_RateOfFuelProduction1(r,l,f,t,m,y)$(OutputActivityRatio(r,t,f,m,y) <> 0)..
    RateOfActivity(r,l,t,m,y)*OutputActivityRatio(r,t,f,m,y) =e= RateOfProductionByTechnologyByMode(r,l,t,m,f,y);

equation EBa2_RateOfFuelProduction2(REGION,TIMESLICE,FUEL,TECHNOLOGY,YEAR);
EBa2_RateOfFuelProduction2(r,l,f,t,y)..
    sum(m$(OutputActivityRatio(r,t,f,m,y) <> 0), RateOfProductionByTechnologyByMode(r,l,t,m,f,y)) =e=
        RateOfProductionByTechnology(r,l,t,f,y);

equation EBa3_RateOfFuelProduction3(REGION,TIMESLICE,FUEL,YEAR);
EBa3_RateOfFuelProduction3(r,l,f,y)..
    sum(t, RateOfProductionByTechnology(r,l,t,f,y)) =e=
        RateOfProduction(r,l,f,y);

equation EBa4_RateOfFuelUse1(REGION,TIMESLICE,FUEL,TECHNOLOGY,MODE_OF_OPERATION,YEAR);
EBa4_RateOfFuelUse1(r,l,f,t,m,y)$(InputActivityRatio(r,t,f,m,y) <> 0)..
    RateOfActivity(r,l,t,m,y)*InputActivityRatio(r,t,f,m,y) =e= RateOfUseByTechnologyByMode(r,l,t,m,f,y);

equation EBa5_RateOfFuelUse2(REGION,TIMESLICE,FUEL,TECHNOLOGY,YEAR);
EBa5_RateOfFuelUse2(r,l,f,t,y)..
    sum(m$(InputActivityRatio(r,t,f,m,y) <> 0), RateOfUseByTechnologyByMode(r,l,t,m,f,y)) =e=
        RateOfUseByTechnology(r,l,t,f,y);

equation EBa6_RateOfFuelUse3(REGION,TIMESLICE,FUEL,YEAR);
EBa6_RateOfFuelUse3(r,l,f,y)..
    sum(t, RateOfUseByTechnology(r,l,t,f,y)) =e= RateOfUse(r,l,f,y);

equation EBa7_EnergyBalanceEachTS1(REGION,TIMESLICE,FUEL,YEAR);
EBa7_EnergyBalanceEachTS1(r,l,f,y)..
    RateOfProduction(r,l,f,y)*YearSplit(l,y) =e= Production(r,l,f,y);

equation EBa8_EnergyBalanceEachTS2(REGION,TIMESLICE,FUEL,YEAR);
EBa8_EnergyBalanceEachTS2(r,l,f,y)..
    RateOfUse(r,l,f,y)*YearSplit(l,y) =e= Use(r,l,f,y);

equation EBa9_EnergyBalanceEachTS3(REGION,TIMESLICE,FUEL,YEAR);
EBa9_EnergyBalanceEachTS3(r,l,f,y)..
    RateOfDemand(r,l,f,y)*YearSplit(l,y) =e= Demand(r,l,f,y);

equation EBa10_EnergyBalanceEachTS4(REGION,r,TIMESLICE,FUEL,YEAR);
EBa10_EnergyBalanceEachTS4(r,rr,l,f,y)..
    Trade(r,rr,l,f,y) =e= -Trade(rr,r,l,f,y);

equation EBa11_EnergyBalanceEachTS5(REGION,TIMESLICE,FUEL,YEAR);
EBa11_EnergyBalanceEachTS5(r,l,f,y)..
    Production(r,l,f,y) =g= Demand(r,l,f,y) + Use(r,l,f,y) + sum(rr, (Trade(r,rr,l,f,y)*TradeRoute(r,rr,f,y)));


*------------------------------------------------------------------------	
* Energy Balance B       
*------------------------------------------------------------------------

* Ensures that demand for each commodity is met in each Year.

equation EBb1_EnergyBalanceEachYear1(REGION,FUEL,YEAR);
EBb1_EnergyBalanceEachYear1(r,f,y)..
    sum(l, Production(r,l,f,y)) =e= ProductionAnnual(r,f,y);

equation EBb2_EnergyBalanceEachYear2(REGION,FUEL,YEAR);
EBb2_EnergyBalanceEachYear2(r,f,y)..
    sum(l, Use(r,l,f,y)) =e= UseAnnual(r,f,y);

equation EBb3_EnergyBalanceEachYear3(REGION,r,FUEL,YEAR);
EBb3_EnergyBalanceEachYear3(r,rr,f,y)..
    sum(l, Trade(r,rr,l,f,y)) =e= TradeAnnual(r,rr,f,y);

equation EBb4_EnergyBalanceEachYear4(REGION,FUEL,YEAR);
EBb4_EnergyBalanceEachYear4(r,f,y)..
    ProductionAnnual(r,f,y) =g= UseAnnual(r,f,y) + sum(rr, (TradeAnnual(r,rr,f,y) * TradeRoute(r,rr,f,y))) + AccumulatedAnnualDemand(r,f,y);



*------------------------------------------------------------------------	
* Accounting Technology Production/Use       
*------------------------------------------------------------------------

* Accounting equations used to generate specific intermediate variables:
* ProductionByTechnology, UseBytechnology,
* TotalAnnualTechnologyActivityByMode, and ModelPeriodCostByRegion.

equation Acc1_FuelProductionByTechnology(REGION,TIMESLICE,TECHNOLOGY,FUEL,YEAR);
Acc1_FuelProductionByTechnology(r,l,t,f,y)..
    RateOfProductionByTechnology(r,l,t,f,y) * YearSplit(l,y) =e= ProductionByTechnology(r,l,t,f,y);

equation Acc2_FuelUseByTechnology(REGION,TIMESLICE,TECHNOLOGY,FUEL,YEAR);
Acc2_FuelUseByTechnology(r,l,t,f,y)..
    RateOfUseByTechnology(r,l,t,f,y) * YearSplit(l,y) =e= UseByTechnology(r,l,t,f,y);

equation Acc3_AverageAnnualRateOfActivity(REGION,TECHNOLOGY,MODE_OF_OPERATION,YEAR);
Acc3_AverageAnnualRateOfActivity(r,t,m,y)..
    sum(l, RateOfActivity(r,l,t,m,y)*YearSplit(l,y)) =e= TotalAnnualTechnologyActivityByMode(r,t,m,y);

equation Acc4_ModelPeriodCostByRegion(REGION);
Acc4_ModelPeriodCostByRegion(r)..
    sum((y), TotalDiscountedCost(r,y)) =e= ModelPeriodCostByRegion(r);




*------------------------------------------------------------------------	
* Storage Equations       
*------------------------------------------------------------------------

$ifthen.storage set storage

equation S1_RateOfStorageCharge(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
S1_RateOfStorageCharge(r,s,ls,ld,lh,y)..
    sum((t,m,l)$(TechnologyToStorage(r,m,t,s)>0),
            RateOfActivity(r,l,t,m,y) * TechnologyToStorage(r,m,t,s) * Conversionls(l,ls) * Conversionld(l,ld) * Conversionlh(l,lh)) =e=
        RateOfStorageCharge(r,s,ls,ld,lh,y);

equation S2_RateOfStorageDischarge(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
S2_RateOfStorageDischarge(r,s,ls,ld,lh,y)..
    sum((t,m,l)$(TechnologyFromStorage(r,m,t,s)>0),
            RateOfActivity(r,l,t,m,y) * TechnologyFromStorage(r,m,t,s) * Conversionls(l,ls) * Conversionld(l,ld) * Conversionlh(l,lh)) =e=
        RateOfStorageDischarge(r,s,ls,ld,lh,y);

equation S3_NetChargeWithinYear(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
S3_NetChargeWithinYear(r,s,ls,ld,lh,y)..
    sum(l$(Conversionls(l,ls)>0 AND Conversionld(l,ld)>0 AND Conversionlh(l,lh)>0),
    (RateOfStorageCharge(r,s,ls,ld,lh,y) - RateOfStorageDischarge(r,s,ls,ld,lh,y)) * YearSplit(l,y) * Conversionls(l,ls) * Conversionld(l,ld) * Conversionlh(l,lh)) =e=
    NetChargeWithinYear(r,s,ls,ld,lh,y);

equation S4_NetChargeWithinDay(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
S4_NetChargeWithinDay(r,s,ls,ld,lh,y)..
    (RateOfStorageCharge(r,s,ls,ld,lh,y) - RateOfStorageDischarge(r,s,ls,ld,lh,y)) * DaySplit(y,lh) =e= NetChargeWithinDay(r,s,ls,ld,lh,y);


StorageLevelYearStart.fx(r,s,y)$(ord(y) eq 1) = StorageLevelStart(r,s);
equation S5_StorageLeveYearStart(REGION,STORAGE,YEAR);
S5_StorageLeveYearStart(r,s,y)$(ord(y) > 1)..
    StorageLevelYearStart(r,s,y-1) + sum((ls,ld,lh), NetChargeWithinYear(r,s,ls,ld,lh,y-1)) =e= StorageLevelYearStart(r,s,y);


equation S7_StorageLevelYearFinish(REGION,STORAGE,YEAR);
S7_StorageLevelYearFinish(r,s,y)$(ord(y) < card(yy))..
    StorageLevelYearStart(r,s,y+1) =e=  StorageLevelYearFinish(r,s,y);
equation S8_StorageLevelYearFinish(REGION,STORAGE,YEAR);
S8_StorageLevelYearFinish(r,s,y)$(ord(y) eq card(yy))..
    StorageLevelYearStart(r,s,y) + sum((ls , ld , lh), NetChargeWithinYear(r,s,ls,ld,lh,y)) =e= StorageLevelYearFinish(r,s,y);


equation S9_StorageLevelSeasonStart(REGION,STORAGE,SEASON,YEAR);
S9_StorageLevelSeasonStart(r,s,ls,y)$(ord(ls) eq 1)..
    StorageLevelSeasonStart(r,s,ls,y) =e= StorageLevelYearStart(r,s,y);
equation S10_StorageLevelSeasonStart(REGION,STORAGE,SEASON,YEAR);
S10_StorageLevelSeasonStart(r,s,ls,y)$(ord(ls) > 1)..
    StorageLevelSeasonStart(r,s,ls,y) =e= StorageLevelSeasonStart(r,s,ls-1,y) + sum((ld,lh), NetChargeWithinYear(r,s,ls-1,ld,lh,y)) ;


equation S11_StorageLevelDayTypeStart(REGION,STORAGE,SEASON,DAYTYPE,YEAR);
S11_StorageLevelDayTypeStart(r,s,ls,ld,y)$(ord(ld) eq 1)..
    StorageLevelSeasonStart(r,s,ls,y) =e=  StorageLevelDayTypeStart(r,s,ls,ld,y);
equation S12_StorageLevelDayTypeStart(REGION,STORAGE,SEASON,DAYTYPE,YEAR);
S12_StorageLevelDayTypeStart(r,s,ls,ld,y)$(ord(ld) > 1)..
    StorageLevelDayTypeStart(r,s,ls,ld-1,y) + sum(lh, NetChargeWithinDay(r,s,ls,ld-1,lh,y) * DaysInDayType(y,ls,ld-1) )  =e=  StorageLevelDayTypeStart(r,s,ls,ld,y);


equation S13_StorageLevelDayTypeFinish(REGION,STORAGE,SEASON,DAYTYPE,YEAR);
S13_StorageLevelDayTypeFinish(r,s,ls,ld,y)$((ord(ld) eq card(ldld)) and (ord(ls) eq card(lsls)))..
    StorageLevelYearFinish(r,s,y) =e= StorageLevelDayTypeFinish(r,s,ls,ld,y);
equation S14_StorageLevelDayTypeFinish(REGION,STORAGE,SEASON,DAYTYPE,YEAR);
S14_StorageLevelDayTypeFinish(r,s,ls,ld,y)$((ord(ld) eq card(ldld)) and (ord(ls) lt card(lsls)))..
    StorageLevelSeasonStart(r,s,ls+1,y) =e= StorageLevelDayTypeFinish(r,s,ls,ld,y);
equation S15_StorageLevelDayTypeFinish(REGION,STORAGE,SEASON,DAYTYPE,YEAR);
S15_StorageLevelDayTypeFinish(r,s,ls,ld,y)$(ord(ld) lt card(ldld))..
    StorageLevelDayTypeFinish(r,s,ls,ld+1,y) - sum(lh,  NetChargeWithinDay(r,s,ls,ld+1,lh,y)  * DaysInDayType(y,ls,ld+1) ) =e= StorageLevelDayTypeFinish(r,s,ls,ld,y);



*------------------------------------------------------------------------	
* Storage Constraints       
*------------------------------------------------------------------------

* SC1_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint
equation SC1_LowerLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC1_LowerLimit(r,s,ls,ld,lh,y)..
    StorageLowerLimit(r,s,y) =l= (StorageLevelDayTypeStart(r,s,ls,ld,y)+sum(lhlh$(ord(lh)-ord(lhlh) > 0),NetChargeWithinDay(r,s,ls,ld,lhlh,y)));

* SC1_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint
equation SC1_UpperLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC1_UpperLimit(r,s,ls,ld,lh,y)..
    StorageLevelDayTypeStart(r,s,ls,ld,y)+sum(lhlh$(ord(lh)-ord(lhlh) > 0),NetChargeWithinDay(r,s,ls,ld,lhlh,y)) =l= StorageUpperLimit(r,s,y);

* SC2_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint
equation SC2_LowerLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC2_LowerLimit(r,s,ls,ld,lh,y)..
    0 =l= (StorageLevelDayTypeStart(r,s,ls,ld,y)-sum(lhlh$(ord(lh)-ord(lhlh) < 0), NetChargeWithinDay(r,s,ls,ld-1,lhlh,y) ))$(ord(ld) > 1)-StorageLowerLimit(r,s,y);

*  SC2_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint
equation  SC2_UpperLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC2_UpperLimit(r,s,ls,ld,lh,y)..
    (StorageLevelDayTypeStart(r,s,ls,ld,y)-sum(lhlh$(ord(lh)-ord(lhlh) < 0), NetChargeWithinDay(r,s,ls,ld-1,lhlh,y)))$(ord(ld) > 1) -StorageUpperLimit(r,s,y) =l= 0;

* SC3_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint
equation SC3_LowerLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC3_LowerLimit(r,s,ls,ld,lh,y)..
    0 =l= (StorageLevelDayTypeFinish(r,s,ls,ld,y) - sum(lhlh$(ord(lh)-ord(lhlh) <0), NetChargeWithinDay(r,s,ls,ld,lhlh,y)))-StorageLowerLimit(r,s,y);

* SC3_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint
equation SC3_UpperLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC3_UpperLimit(r,s,ls,ld,lh,y)..
    (StorageLevelDayTypeFinish(r,s,ls,ld,y) - sum(lhlh$(ord(lh)-ord(lhlh) <0), NetChargeWithinDay(r,s,ls,ld,lhlh,y)) )-StorageUpperLimit(r,s,y) =l= 0;

* SC4_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint
equation SC4_LowerLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC4_LowerLimit(r,s,ls,ld,lh,y)..
    0 =L= (StorageLevelDayTypeFinish(r,s,ls,ld-1,y)+sum(lhlh$(ord(lh)-ord(lhlh) >0), NetChargeWithinDay(r,s,ls,ld,lhlh,y) ))$(ord(ld) > 1) -StorageLowerLimit(r,s,y);

* SC4_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint
equation SC4_UpperLimit(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC4_UpperLimit(r,s,ls,ld,lh,y)..
    (StorageLevelDayTypeFinish(r,s,ls,ld-1,y)+sum(lhlh$(ord(lh)-ord(lhlh) >0), NetChargeWithinDay(r,s,ls,ld,lhlh,y) ))$(ord(ld) > 1) -StorageUpperLimit(r,s,y) =l= 0;

equation SC5_MaxChargeConstraint(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC5_MaxChargeConstraint(r,s,ls,ld,lh,y)..
    RateOfStorageCharge(r,s,ls,ld,lh,y) =l= StorageMaxChargeRate(r,s);

equation SC6_MaxDischargeConstraint(REGION,STORAGE,SEASON,DAYTYPE,DAILYTIMEBRACKET,YEAR);
SC6_MaxDischargeConstraint(r,s,ls,ld,lh,y)..
    RateOfStorageDischarge(r,s,ls,ld,lh,y) =l= StorageMaxDischargeRate(r,s);



*------------------------------------------------------------------------	
* Storage investments       
*------------------------------------------------------------------------

* Calculates the total discounted capital costs expenditure for each
* storage technology in each year.

equation SI1_StorageUpperLimit(REGION,STORAGE,YEAR);
SI1_StorageUpperLimit(r,s,y)..
    AccumulatedNewStorageCapacity(r,s,y)+ResidualStorageCapacity(r,s,y) =e= StorageUpperLimit(r,s,y);

equation SI2_StorageLowerLimit(REGION,STORAGE,YEAR);
SI2_StorageLowerLimit(r,s,y)..
    MinStorageCharge(r,s,y)*StorageUpperLimit(r,s,y) =e= StorageLowerLimit(r,s,y);

equation SI3_TotalNewStorage(REGION,STORAGE,YEAR);
SI3_TotalNewStorage(r,s,y)..
    sum(yy$(y.val-yy.val < OperationalLifeStorage(r,s) and y.val-yy.val gt 0), NewStorageCapacity(r,s,yy)) =e= AccumulatedNewStorageCapacity(r,s,y);

equation SI4_UndiscountedCapitalInvestmentStorage(REGION,STORAGE,YEAR);
SI4_UndiscountedCapitalInvestmentStorage(r,s,y)..
    CapitalCostStorage(r,s,y) * NewStorageCapacity(r,s,y) =e= CapitalInvestmentStorage(r,s,y);

equation SI5_DiscountingCapitalInvestmentStorage(REGION,STORAGE,YEAR);
SI5_DiscountingCapitalInvestmentStorage(r,s,y)..
    CapitalInvestmentStorage(r,s,y)/((1+DiscountRate(r))**(y.val-smin(yy,yy.val))) =e= DiscountedCapitalInvestmentStorage(r,s,y);

equation SI6_SalvageValueStorageAtEndOfPeriod1(REGION,STORAGE,YEAR);
SI6_SalvageValueStorageAtEndOfPeriod1(r,s,y)$((y.val+OperationalLifeStorage(r,s)-1) le smax(yy,yy.val))..
    0 =e= SalvageValueStorage(r,s,y);

equation SI7_SalvageValueStorageAtEndOfPeriod2(REGION,STORAGE,YEAR);
SI7_SalvageValueStorageAtEndOfPeriod2(r,s,y)$(((DepreciationMethod(r) eq 1) and (y.val+OperationalLifeStorage(r,s)-1) > smax(yy,yy.val) and DiscountRate(r)=0) or ((DepreciationMethod(r) eq 2) and (y.val+OperationalLifeStorage(r,s)-1) > smax(yy,yy.val)))..
    CapitalInvestmentStorage(r,s,y)*(1 - (sum(yy$(ord(yy) eq card(yyy)),yy.val) - y.val+1)/OperationalLifeStorage(r,s)) =e= SalvageValueStorage(r,s,y);

equation SI8_SalvageValueStorageAtEndOfPeriod3(REGION,STORAGE,YEAR);
SI8_SalvageValueStorageAtEndOfPeriod3(r,s,y)$(DepreciationMethod(r)=1 and ((y.val+OperationalLifeStorage(r,s)-1) > smax(yy,yy.val) and DiscountRate(r)>0))..
    CapitalInvestmentStorage(r,s,y)*(1-(((1+DiscountRate(r))**(smax(yy,yy.val)-y.val+1)-1)/((1+DiscountRate(r))**OperationalLifeStorage(r,s)-1))) =e= SalvageValueStorage(r,s,y);

equation SI9_SalvageValueStorageDiscountedToStartYear(REGION,STORAGE,YEAR);
SI9_SalvageValueStorageDiscountedToStartYear(r,s,y)..
    SalvageValueStorage(r,s,y)/((1+DiscountRate(r))**(smax(yy,yy.val)-smin(yy,yy.val) +1)) =e= DiscountedSalvageValueStorage(r,s,y);

equation SI10_TotalDiscountedCostByStorage(REGION,STORAGE,YEAR);
SI10_TotalDiscountedCostByStorage(r,s,y)..
    DiscountedCapitalInvestmentStorage(r,s,y)-DiscountedSalvageValueStorage(r,s,y) =e= TotalDiscountedStorageCost(r,s,y);
$endif.storage


*------------------------------------------------------------------------	
* Capital costs       
*------------------------------------------------------------------------

* Calculates the total discounted capital cost expenditure for each
* technology in each year.

equation CC1_UndiscountedCapitalInvestment(REGION,TECHNOLOGY,YEAR);
CC1_UndiscountedCapitalInvestment(r,t,y)..
    CapitalCost(r,t,y) * NewCapacity(r,t,y) =e= CapitalInvestment(r,t,y);

equation CC2_DiscountingCapitalInvestmenta(REGION,TECHNOLOGY,YEAR);
CC2_DiscountingCapitalInvestmenta(r,t,y)..
    CapitalInvestment(r,t,y)/((1+DiscountRate(r))**(y.val-smin(yy, yy.val))) =e= DiscountedCapitalInvestment(r,t,y);



*------------------------------------------------------------------------	
* Salvage value       
*------------------------------------------------------------------------

* Calculates the fraction of the initial capital cost that can be recouped
* at the end of a technologies operational life. The salvage value can be
* calculated using one of two depreciation methods: straight line and
* sinking fund.

equation SV1_SalvageValueAtEndOfPeriod1(REGION,TECHNOLOGY,YEAR);
SV1_SalvageValueAtEndOfPeriod1(r,t,y)$((DepreciationMethod(r) eq 1) and (((y.val + OperationalLife(r,t)-1) > smax(yy, yy.val)) and (DiscountRate(r) > 0)))..
    SalvageValue(r,t,y) =e= CapitalCost(r,t,y)*NewCapacity(r,t,y)*(1-(((1+DiscountRate(r))**(smax(yy, yy.val) - y.val+1) -1) /((1+DiscountRate(r))**OperationalLife(r,t)-1)));

equation SV2_SalvageValueAtEndOfPeriod2(REGION,TECHNOLOGY,YEAR);
SV2_SalvageValueAtEndOfPeriod2(r,t,y)$((((y.val + OperationalLife(r,t)-1) > smax(yy, yy.val)) and (DiscountRate(r) eq 0)) or ((DepreciationMethod(r) eq 2) and ((y.val + OperationalLife(r,t)-1) > smax(yy, yy.val))))..
    SalvageValue(r,t,y) =e= CapitalCost(r,t,y)*NewCapacity(r,t,y)*(1-(smax(yy, yy.val)- y.val+1)/OperationalLife(r,t));

equation SV3_SalvageValueAtEndOfPeriod3(REGION,TECHNOLOGY,YEAR);
SV3_SalvageValueAtEndOfPeriod3(r,t,y)$(y.val + OperationalLife(r,t)-1 <= smax(yy, yy.val))..
    SalvageValue(r,t,y) =e= 0;

equation SV4_SalvageValueDiscToStartYr(REGION,TECHNOLOGY,YEAR);
SV4_SalvageValueDiscToStartYr(r,t,y)..
    DiscountedSalvageValue(r,t,y) =e= SalvageValue(r,t,y)/((1+DiscountRate(r))**(1+smax(yy, yy.val) - smin(yy, yy.val)));
    

*------------------------------------------------------------------------	
* Operating costs       
*------------------------------------------------------------------------

* Calculates the total variable and fixed operating costs for each
* technology, in each year.

equation OC1_OperatingCostsVariable(REGION,TIMESLICE,TECHNOLOGY,YEAR);
OC1_OperatingCostsVariable(r,l,t,y)..
    sum(m, (TotalAnnualTechnologyActivityByMode(r,t,m,y)*VariableCost(r,t,m,y))) =e=
        AnnualVariableOperatingCost(r,t,y);

equation OC2_OperatingCostsFixedAnnual(REGION,TECHNOLOGY,YEAR);
OC2_OperatingCostsFixedAnnual(r,t,y)..
    TotalCapacityAnnual(r,t,y)*FixedCost(r,t,y) =e= AnnualFixedOperatingCost(r,t,y);

equation OC3_OperatingCostsTotalAnnual(REGION,TECHNOLOGY,YEAR);
OC3_OperatingCostsTotalAnnual(r,t,y)..
    AnnualFixedOperatingCost(r,t,y)+AnnualVariableOperatingCost(r,t,y) =e= OperatingCost(r,t,y);

equation OC4_DiscountedOperatingCostsTotalAnnual(REGION,TECHNOLOGY,YEAR);
OC4_DiscountedOperatingCostsTotalAnnual(r,t,y)..
    OperatingCost(r,t,y)/((1+DiscountRate(r))**(y.val-smin(yy, yy.val)+0.5)) =e= DiscountedOperatingCost(r,t,y);
    
*
* ############### Total Discounted Costs #############
*


*------------------------------------------------------------------------	
* Total discounted costs
*------------------------------------------------------------------------

* Calculates the total discounted system cost over the entire model period
* to give the TotalDiscountedCost. This is the variable that is minimized
* in the model’s objective function.

equation TDC1_TotalDiscountedCostByTechnology(REGION,TECHNOLOGY,YEAR);
TDC1_TotalDiscountedCostByTechnology(r,t,y)..
    DiscountedOperatingCost(r,t,y)+DiscountedCapitalInvestment(r,t,y)+DiscountedTechnologyEmissionsPenalty(r,t,y)-DiscountedSalvageValue(r,t,y) =e= TotalDiscountedCostByTechnology(r,t,y);

equation TDC2_TotalDiscountedCostByTechnology(REGION,YEAR);
TDC2_TotalDiscountedCostByTechnology(r,y)..
    sum(t, TotalDiscountedCostByTechnology(r,t,y)) + sum(s,TotalDiscountedStorageCost(r,s,y)) =e= TotalDiscountedCost(r,y);



*------------------------------------------------------------------------	
* Total capacity constraints
*------------------------------------------------------------------------

* Ensures that the total capacity of each technology in each year is
* greater than and less than the user-defined parameters
* TotalAnnualMinCapacityInvestment and TotalAnnualMaxCapacityInvestment
* respectively.

equation TCC1_TotalAnnualMaxCapacityConstraint(REGION,TECHNOLOGY,YEAR);
TCC1_TotalAnnualMaxCapacityConstraint(r,t,y)..
    TotalCapacityAnnual(r,t,y) =l= TotalAnnualMaxCapacity(r,t,y);

equation TCC2_TotalAnnualMinCapacityConstraint(REGION,TECHNOLOGY,YEAR);
TCC2_TotalAnnualMinCapacityConstraint(r,t,y)$(TotalAnnualMinCapacity(r,t,y)>0)..
    TotalCapacityAnnual(r,t,y) =g= TotalAnnualMinCapacity(r,t,y);



*------------------------------------------------------------------------	
* New capacity constraints
*------------------------------------------------------------------------

* Ensures that the new capacity of each technology installed in each year
* is greater than and less than the user-defined parameters
* TotalAnnualMinCapacityInvestment and TotalAnnualMaxCapacityInvestment
* respectively.

equation NCC1_TotalAnnualMaxNewCapacityConstraint(REGION,TECHNOLOGY,YEAR);
NCC1_TotalAnnualMaxNewCapacityConstraint(r,t,y)..
    NewCapacity(r,t,y) =l= TotalAnnualMaxCapacityInvestment(r,t,y);

equation NCC2_TotalAnnualMinNewCapacityConstraint(REGION,TECHNOLOGY,YEAR);
NCC2_TotalAnnualMinNewCapacityConstraint(r,t,y)$(TotalAnnualMinCapacityInvestment(r,t,y) > 0)..
    NewCapacity(r,t,y) =g= TotalAnnualMinCapacityInvestment(r,t,y);



*------------------------------------------------------------------------	
* Annual activity constraints
*------------------------------------------------------------------------

* Ensures that the total activity of each technology over each year is
* greater than and less than the user-defined parameters
* TotalTechnologyAnnualActivityLowerLimit and
* TotalTechnologyAnnualActivityUpperLimit respectively.

equation AAC1_TotalAnnualTechnologyActivity(REGION,TECHNOLOGY,YEAR);
AAC1_TotalAnnualTechnologyActivity(r,t,y)..
    sum(l, (RateOfTotalActivity(r,l,t,y)*YearSplit(l,y))) =e= TotalTechnologyAnnualActivity(r,t,y);

equation AAC2_TotalAnnualTechnologyActivityUpperLimit(REGION,TECHNOLOGY,YEAR);
AAC2_TotalAnnualTechnologyActivityUpperLimit(r,t,y)..
    TotalTechnologyAnnualActivity(r,t,y) =l= TotalTechnologyAnnualActivityUpperLimit(r,t,y);

equation AAC3_TotalAnnualTechnologyActivityLowerLimit(REGION,TECHNOLOGY,YEAR);
AAC3_TotalAnnualTechnologyActivityLowerLimit(r,t,y)$(TotalTechnologyAnnualActivityLowerLimit(r,t,y) > 0)..
    TotalTechnologyAnnualActivity(r,t,y) =g= TotalTechnologyAnnualActivityLowerLimit(r,t,y);



*------------------------------------------------------------------------	
* Total activity constraints
*------------------------------------------------------------------------

* Ensures that the total activity of each technology over the entire model
* period is greater than and less than the user-defined parameters
* TotalTechnologyModelPeriodActivityLowerLimit and
* TotalTechnologyModelPeriodActivityUpperLimit respectively.

equation TAC1_TotalModelHorizenTechnologyActivity(REGION,TECHNOLOGY);
TAC1_TotalModelHorizenTechnologyActivity(r,t)..
    sum(y, TotalTechnologyAnnualActivity(r,t,y)) =e= TotalTechnologyModelPeriodActivity(r,t);

equation TAC2_TotalModelHorizenTechnologyActivityUpperLimit(REGION,TECHNOLOGY,YEAR);
TAC2_TotalModelHorizenTechnologyActivityUpperLimit(r,t,y)$(TotalTechnologyModelPeriodActivityUpperLimit(r,t) > 0)..
    TotalTechnologyModelPeriodActivity(r,t) =l= TotalTechnologyModelPeriodActivityUpperLimit(r,t);

equation TAC3_TotalModelHorizenTechnologyActivityLowerLimit(REGION,TECHNOLOGY,YEAR);
TAC3_TotalModelHorizenTechnologyActivityLowerLimit(r,t,y)$(TotalTechnologyModelPeriodActivityLowerLimit(r,t) > 0)..
    TotalTechnologyModelPeriodActivity(r,t) =g= TotalTechnologyModelPeriodActivityLowerLimit(r,t);
    


*------------------------------------------------------------------------	
* Reserve margin constraints
*------------------------------------------------------------------------

* Ensures that sufficient reserve capacity of specific technologies
* (ReserveMarginTagTechnology = 1) is installed such that the user-defined
* ReserveMargin is maintained.

equation RM1_ReserveMargin_TechologiesIncluded_In_Activity_Units(REGION,TIMESLICE,YEAR);
RM1_ReserveMargin_TechologiesIncluded_In_Activity_Units(r,l,y)..
    sum (t,TotalCapacityAnnual(r,t,y) * ReserveMarginTagTechnology(r,t,y) * CapacityToActivityUnit(r,t)) =e= TotalCapacityInReserveMargin(r,y);

equation RM2_ReserveMargin_FuelsIncluded(REGION,TIMESLICE,YEAR);
RM2_ReserveMargin_FuelsIncluded(r,l,y)..
    sum (f, RateOfProduction(r,l,f,y) * ReserveMarginTagFuel(r,f,y)) =e= DemandNeedingReserveMargin(r,l,y);

equation RM3_ReserveMargin_Constraint(REGION,TIMESLICE,YEAR);
RM3_ReserveMargin_Constraint(r,l,y)..
    DemandNeedingReserveMargin(r,l,y) * ReserveMargin(r,y) =l= TotalCapacityInReserveMargin(r,y);
    

*------------------------------------------------------------------------	
* RE production target
*------------------------------------------------------------------------

* Ensures that production from technologies tagged as renewable energy
* technologies (RETagTechnology = 1) is at least equal to the user-defined
* renewable energy (RE) target.

equation RE1_FuelProductionByTechnologyAnnual(REGION,TECHNOLOGY,FUEL,YEAR);
RE1_FuelProductionByTechnologyAnnual(r,t,f,y)..
    sum(l, ProductionByTechnology(r,l,t,f,y)) =e= ProductionByTechnologyAnnual(r,t,f,y);

equation RE2_TechIncluded(REGION,YEAR);
RE2_TechIncluded(r,y)..
    sum((t,f), (ProductionByTechnologyAnnual(r,t,f,y)*RETagTechnology(r,t,y))) =e= TotalREProductionAnnual(r,y);

equation RE3_FuelIncluded(REGION,YEAR);
RE3_FuelIncluded(r,y)..
    sum((l,f), (RateOfProduction(r,l,f,y)*YearSplit(l,y)*RETagFuel(r,f,y))) =e= RETotalProductionOfTargetFuelAnnual(r,y);

equation RE4_EnergyConstraint(REGION,YEAR);
RE4_EnergyConstraint(r,y)..
    REMinProductionTarget(r,y)*RETotalProductionOfTargetFuelAnnual(r,y) =l= TotalREProductionAnnual(r,y);

equation RE5_FuelUseByTechnologyAnnual(REGION,TECHNOLOGY,FUEL,YEAR);
RE5_FuelUseByTechnologyAnnual(r,t,f,y)..
    sum(l, (RateOfUseByTechnology(r,l,t,f,y)*YearSplit(l,y))) =e= UseByTechnologyAnnual(r,t,f,y);



*------------------------------------------------------------------------	
* Emissions accounting
*------------------------------------------------------------------------

* Calculates the annual and model period emissions from each technology,
* for each type of emission. It also calculates the total associated
* emission penalties, if any. Finally, it ensures that emissions are
* maintained before stipulated limits that may be defined for each year
* and/or the entire model period.

equation E1_AnnualEmissionProductionByMode(REGION,TECHNOLOGY,EMISSION,MODE_OF_OPERATION,YEAR);
E1_AnnualEmissionProductionByMode(r,t,e,m,y)..
    EmissionActivityRatio(r,t,e,m,y)*TotalAnnualTechnologyActivityByMode(r,t,m,y) =e= AnnualTechnologyEmissionByMode(r,t,e,m,y);

equation E2_AnnualEmissionProduction(REGION,TECHNOLOGY,EMISSION,YEAR);
E2_AnnualEmissionProduction(r,t,e,y)..
    sum(m, AnnualTechnologyEmissionByMode(r,t,e,m,y)) =e= AnnualTechnologyEmission(r,t,e,y);

equation E3_EmissionsPenaltyByTechAndEmission(REGION,TECHNOLOGY,EMISSION,YEAR);
E3_EmissionsPenaltyByTechAndEmission(r,t,e,y)..
    AnnualTechnologyEmission(r,t,e,y)*EmissionsPenalty(r,e,y) =e= AnnualTechnologyEmissionPenaltyByEmission(r,t,e,y);

equation E4_EmissionsPenaltyByTechnology(REGION,TECHNOLOGY,YEAR);
E4_EmissionsPenaltyByTechnology(r,t,y)..
    sum(e, AnnualTechnologyEmissionPenaltyByEmission(r,t,e,y)) =e= AnnualTechnologyEmissionsPenalty(r,t,y);

equation E5_DiscountedEmissionsPenaltyByTechnology(REGION,TECHNOLOGY,YEAR);
E5_DiscountedEmissionsPenaltyByTechnology(r,t,y)..
    AnnualTechnologyEmissionsPenalty(r,t,y)/((1+DiscountRate(r))**(y.val-smin(yy, yy.val)+0.5)) =e= DiscountedTechnologyEmissionsPenalty(r,t,y);

equation E6_EmissionsAccounting1(REGION,EMISSION,YEAR);
E6_EmissionsAccounting1(r,e,y)..
    sum(t, AnnualTechnologyEmission(r,t,e,y)) =e= AnnualEmissions(r,e,y);

equation E7_EmissionsAccounting2(EMISSION,REGION);
E7_EmissionsAccounting2(e,r)..
    sum(y, AnnualEmissions(r,e,y)) =e= ModelPeriodEmissions(e,r)- ModelPeriodExogenousEmission(r,e);

equation E8_AnnualEmissionsLimit(REGION,EMISSION,YEAR);
E8_AnnualEmissionsLimit(r,e,y)..
    AnnualEmissions(r,e,y)+AnnualExogenousEmission(r,e,y) =l= AnnualEmissionLimit(r,e,y);

equation E9_ModelPeriodEmissionsLimit(EMISSION,REGION);
E9_ModelPeriodEmissionsLimit(e,r)..
    ModelPeriodEmissions(e,r) =l= ModelPeriodEmissionLimit(r,e);
