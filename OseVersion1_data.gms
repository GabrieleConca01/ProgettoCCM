 * UTOPIA_DATA.GMS - specify Utopia Model data
 
*#      Energy and demand in GW
*#      Power plants in GW
*#      Investment and Fixed O&M Costs: Power plant: Million $ / GW (//$/kW)
*#      Investment  and Fixed O&M Costs Costs: Other plant costs: Million $/PJ/a
*#      Variable O&M (& Import) Costs: Million $ / PJ (//$/GJ)


*------------------------------------------------------------------------	
* Sets       
*------------------------------------------------------------------------

set     YEAR    / 2022*2100 /;
set     TECHNOLOGY      /
        PHyd 'hydroelecrtric plant'
        PSol 'solar plant'
        PEol 'wind farms'
        GDie 'Diesel generator'

        IMPD 'Diesel imports'
        
        SHyd 'Storage hydro'
        SCar 'Storage by cars'
    
        AD 'Personal vehicles - diesel'
        AE 'Personal vehicles - electric'
        AI 'Personal vehicles - hibrid'
        FD 'Small trucks - diesel'
        FE 'Small trucks - electric'
        FI 'Small trucks - hybrid'
/;

set     TIMESLICE       /
        ID 'Intermediate - day'
        IN 'Intermediate - night'
        SD 'Summer - day'
        SN 'Summer - night'
        WD 'Winter - day'
        WN 'Winter - night'
/;

set     FUEL    /
        DSL 'Diesel'
        ELC 'Electricity'
        HYD 'Hydro'
        SOL 'Solar'
        
        DA 'Demand for personal transport'
        DF 'Demand for small trucks'
/;

set     EMISSION        / CO2, NOX /;
set     MODE_OF_OPERATION       / 1, 2 /;
set     REGION  / Italy /;
set     SEASON / 1, 2, 3 /;
set     DAYTYPE / 1 /;
set     DAILYTIMEBRACKET / 1, 2 /;
set     STORAGE / DAM /;

# characterize technologies 
set power_plants(TECHNOLOGY) / PSol, PHyd, PEol,GDie /;
set storage_plants(TECHNOLOGY) / SHyd, SCar /;
set fuel_transformation(TECHNOLOGY) / SRE /;
set appliances(TECHNOLOGY) / RHE, RHO, RL1, TXD, TXE, TXG /;
set unmet_demand(TECHNOLOGY) / /;
set transport(TECHNOLOGY) / TXD, TXE, TXG /;
set primary_imports(TECHNOLOGY) / IMPHCO1, IMPOIL1, IMPURN1 /;
set secondary_imports(TECHNOLOGY) / IMPDSL1, IMPGSL1 /;

set renewable_tech(TECHNOLOGY) /HYDRO/; 
set renewable_fuel(FUEL) /HYD/; 

set fuel_production(TECHNOLOGY);
set fuel_production_fict(TECHNOLOGY) /RIV/;
set secondary_production(TECHNOLOGY) /COAL, NUCLEAR, HYDRO, STOR_HYDRO, DIESEL_GEN, SRE/;

#Characterize fuels 
set primary_fuel(FUEL) / HCO, OIL, URN, HYD /;
set secondary_carrier(FUEL) / DSL, GSL, ELC /;
set final_demand(FUEL) / RH, RL, TX /;

*$include "Model/osemosys_init.gms"

*------------------------------------------------------------------------	
* Parameters - Global
*------------------------------------------------------------------------


parameter YearSplit(l,y) /
  ID.(1990*2010)  .3333
  IN.(1990*2010)  .1667
  SD.(1990*2010)  .1667
  SN.(1990*2010)  .0833
  WD.(1990*2010)  .1667
  WN.(1990*2010)  .0833
/;

DiscountRate(r) = 0.05;

DaySplit(y,lh) = 12/(24*365);

parameter Conversionls(l,ls) /
ID.2 1
IN.2 1
SD.3 1
SN.3 1
WD.1 1
WN.1 1
/;

parameter Conversionld(l,ld) /
ID.1 1
IN.1 1
SD.1 1
SN.1 1
WD.1 1
WN.1 1
/;

parameter Conversionlh(l,lh) /
ID.1 1
IN.2 1
SD.1 1 
SN.2 1
WD.1 1
WN.2 1
/;

DaysInDayType(y,ls,ld) = 7;

TradeRoute(r,rr,f,y) = 0;

DepreciationMethod(r) = 1;


*------------------------------------------------------------------------	
* Parameters - Demands       
*------------------------------------------------------------------------

parameter SpecifiedAnnualDemand(r,f,y) /
  UTOPIA.RH.1990  25.2
  UTOPIA.RH.1991  26.46
  UTOPIA.RH.1992  27.72
  UTOPIA.RH.1993  28.98
  UTOPIA.RH.1994  30.24
  UTOPIA.RH.1995  31.5
  UTOPIA.RH.1996  32.76
  UTOPIA.RH.1997  34.02
  UTOPIA.RH.1998  35.28
  UTOPIA.RH.1999  36.54
  UTOPIA.RH.2000  37.8
  UTOPIA.RH.2001  39.69
  UTOPIA.RH.2002  41.58
  UTOPIA.RH.2003  43.47
  UTOPIA.RH.2004  45.36
  UTOPIA.RH.2005  47.25
  UTOPIA.RH.2006  49.14
  UTOPIA.RH.2007  51.03
  UTOPIA.RH.2008  52.92
  UTOPIA.RH.2009  54.81
  UTOPIA.RH.2010  56.7
  UTOPIA.RL.1990  5.6
  UTOPIA.RL.1991  5.88
  UTOPIA.RL.1992  6.16
  UTOPIA.RL.1993  6.44
  UTOPIA.RL.1994  6.72
  UTOPIA.RL.1995  7
  UTOPIA.RL.1996  7.28
  UTOPIA.RL.1997  7.56
  UTOPIA.RL.1998  7.84
  UTOPIA.RL.1999  8.12
  UTOPIA.RL.2000  8.4
  UTOPIA.RL.2001  8.82
  UTOPIA.RL.2002  9.24
  UTOPIA.RL.2003  9.66
  UTOPIA.RL.2004  10.08
  UTOPIA.RL.2005  10.5
  UTOPIA.RL.2006  10.92
  UTOPIA.RL.2007  11.34
  UTOPIA.RL.2008  11.76
  UTOPIA.RL.2009  12.18
  UTOPIA.RL.2010  12.6
/;

parameter SpecifiedDemandProfile(r,f,l,y) /
  UTOPIA.RH.ID.(1990*2010)  .12
  UTOPIA.RH.IN.(1990*2010)  .06
  UTOPIA.RH.SD.(1990*2010)  0
  UTOPIA.RH.SN.(1990*2010)  0
  UTOPIA.RH.WD.(1990*2010)  .5467
  UTOPIA.RH.WN.(1990*2010)  .2733
  UTOPIA.RL.ID.(1990*2010)  .15
  UTOPIA.RL.IN.(1990*2010)  .05
  UTOPIA.RL.SD.(1990*2010)  .15
  UTOPIA.RL.SN.(1990*2010)  .05
  UTOPIA.RL.WD.(1990*2010)  .5
  UTOPIA.RL.WN.(1990*2010)  .1
/;

parameter AccumulatedAnnualDemand(r,f,y) /
  UTOPIA.TX.1990  5.2
  UTOPIA.TX.1991  5.46
  UTOPIA.TX.1992  5.72
  UTOPIA.TX.1993  5.98
  UTOPIA.TX.1994  6.24
  UTOPIA.TX.1995  6.5
  UTOPIA.TX.1996  6.76
  UTOPIA.TX.1997  7.02
  UTOPIA.TX.1998  7.28
  UTOPIA.TX.1999  7.54
  UTOPIA.TX.2000  7.8
  UTOPIA.TX.2001  8.189
  UTOPIA.TX.2002  8.578
  UTOPIA.TX.2003  8.967
  UTOPIA.TX.2004  9.356
  UTOPIA.TX.2005  9.745
  UTOPIA.TX.2006  10.134
  UTOPIA.TX.2007  10.523
  UTOPIA.TX.2008  10.912
  UTOPIA.TX.2009  11.301
  UTOPIA.TX.2010  11.69
/;

*------------------------------------------------------------------------	
* Parameters - Performance       
*------------------------------------------------------------------------

CapacityToActivityUnit(r,t)$power_plants(t) = 31.536;

CapacityToActivityUnit(r,t)$(CapacityToActivityUnit(r,t) = 0) = 1;

CapacityFactor(r,'COAL',l,y) = 0.8;
CapacityFactor(r,'NUCLEAR',l,y) = 0.8;
CapacityFactor(r,'HYDRO',l,y) = 0.27;
CapacityFactor(r,'STOR_HYDRO',l,y) = 0.17;
CapacityFactor(r,'DIESEL_GEN',l,y) = 0.8;
CapacityFactor(r,t,l,y)$(CapacityFactor(r,t,l,y) = 0) = 1;

AvailabilityFactor(r,t,y) = 1;

parameter OperationalLife(r,t) /
  UTOPIA.COAL  40
  UTOPIA.NUCLEAR  40
  UTOPIA.HYDRO  100
  UTOPIA.STOR_HYDRO  100
  UTOPIA.DIESEL_GEN  40
  UTOPIA.RHE  30
  UTOPIA.RHO  30
  UTOPIA.RL1  10
  UTOPIA.SRE  50
  UTOPIA.TXD  15
  UTOPIA.TXE  15
  UTOPIA.TXG  15
/;
OperationalLife(r,t)$(OperationalLife(r,t) = 0) = 1;

parameter ResidualCapacity(r,t,y) /
  UTOPIA.COAL.1990  .5
  UTOPIA.COAL.1991  .5
  UTOPIA.COAL.1992  .5
  UTOPIA.COAL.1993  .4
  UTOPIA.COAL.1994  .4
  UTOPIA.COAL.1995  .4
  UTOPIA.COAL.1996  .4
  UTOPIA.COAL.1997  .4
  UTOPIA.COAL.1998  .4
  UTOPIA.COAL.1999  .3
  UTOPIA.COAL.2000  .3
  UTOPIA.COAL.2001  .3
  UTOPIA.COAL.2002  .3
  UTOPIA.COAL.2003  .3
  UTOPIA.COAL.2004  .3
  UTOPIA.COAL.2005  .2
  UTOPIA.COAL.2006  .2
  UTOPIA.COAL.2007  .2
  UTOPIA.COAL.2008  .2
  UTOPIA.COAL.2009  .2
  UTOPIA.COAL.2010  .15
  UTOPIA.NUCLEAR.(1990*2010)  0
  UTOPIA.HYDRO.(1990*2010)  .1
  UTOPIA.STOR_HYDRO.(1990*2010)  .5
  UTOPIA.DIESEL_GEN.1990  .3
  UTOPIA.DIESEL_GEN.1991  .3
  UTOPIA.DIESEL_GEN.1992  .29
  UTOPIA.DIESEL_GEN.1993  .29
  UTOPIA.DIESEL_GEN.1994  .28
  UTOPIA.DIESEL_GEN.1995  .28
  UTOPIA.DIESEL_GEN.1996  .27
  UTOPIA.DIESEL_GEN.1997  .27
  UTOPIA.DIESEL_GEN.1998  .26
  UTOPIA.DIESEL_GEN.1999  .26
  UTOPIA.DIESEL_GEN.2000  .25
  UTOPIA.DIESEL_GEN.2001  .25
  UTOPIA.DIESEL_GEN.2002  .24
  UTOPIA.DIESEL_GEN.2003  .24
  UTOPIA.DIESEL_GEN.2004  .23
  UTOPIA.DIESEL_GEN.2005  .23
  UTOPIA.DIESEL_GEN.2006  .22
  UTOPIA.DIESEL_GEN.2007  .22
  UTOPIA.DIESEL_GEN.2008  .21
  UTOPIA.DIESEL_GEN.2009  .21
  UTOPIA.DIESEL_GEN.2010  .2
  UTOPIA.RHE.(1990*2010)  0
  UTOPIA.RHO.1990  25
  UTOPIA.RHO.1991  23.8
  UTOPIA.RHO.1992  22.5
  UTOPIA.RHO.1993  21.3
  UTOPIA.RHO.1994  20
  UTOPIA.RHO.1995  18.8
  UTOPIA.RHO.1996  17.5
  UTOPIA.RHO.1997  16.3
  UTOPIA.RHO.1998  15
  UTOPIA.RHO.1999  13.8
  UTOPIA.RHO.2000  12.5
  UTOPIA.RHO.2001  11.3
  UTOPIA.RHO.2002  10
  UTOPIA.RHO.2003  8.8
  UTOPIA.RHO.2004  7.5
  UTOPIA.RHO.2005  6.3
  UTOPIA.RHO.2006  5
  UTOPIA.RHO.2007  3.8
  UTOPIA.RHO.2008  2.5
  UTOPIA.RHO.2009  1.3
  UTOPIA.RHO.2010  0
  UTOPIA.RL1.1990  5.6
  UTOPIA.RL1.1991  5
  UTOPIA.RL1.1992  4.5
  UTOPIA.RL1.1993  3.9
  UTOPIA.RL1.1994  3.4
  UTOPIA.RL1.1995  2.8
  UTOPIA.RL1.1996  2.2
  UTOPIA.RL1.1997  1.7
  UTOPIA.RL1.1998  1.1
  UTOPIA.RL1.1999  .6
  UTOPIA.RL1.2000  0
  UTOPIA.RL1.2001  0
  UTOPIA.RL1.2002  0
  UTOPIA.RL1.2003  0
  UTOPIA.RL1.2004  0
  UTOPIA.RL1.2005  0
  UTOPIA.RL1.2006  0
  UTOPIA.RL1.2007  0
  UTOPIA.RL1.2008  0
  UTOPIA.RL1.2009  0
  UTOPIA.RL1.2010  0
  UTOPIA.TXD.1990  .6
  UTOPIA.TXD.1991  .6
  UTOPIA.TXD.1992  .5
  UTOPIA.TXD.1993  .5
  UTOPIA.TXD.1994  .4
  UTOPIA.TXD.1995  .4
  UTOPIA.TXD.1996  .4
  UTOPIA.TXD.1997  .3
  UTOPIA.TXD.1998  .3
  UTOPIA.TXD.1999  .2
  UTOPIA.TXD.2000  .2
  UTOPIA.TXD.2001  .2
  UTOPIA.TXD.2002  .2
  UTOPIA.TXD.2003  .1
  UTOPIA.TXD.2004  .1
  UTOPIA.TXD.2005  .1
  UTOPIA.TXD.2006  .1
  UTOPIA.TXD.2007  .1
  UTOPIA.TXD.2008  0
  UTOPIA.TXD.2009  0
  UTOPIA.TXD.2010  0
/;
$if set no_initial_capacity ResidualCapacity(r,t,y) = 0;

parameter InputActivityRatio(r,t,f,m,y) /
  UTOPIA.COAL.HCO.1.(1990*2010)  3.125
  UTOPIA.NUCLEAR.URN.1.(1990*2010)  3.5
  UTOPIA.HYDRO.HYD.1.(1990*2010)  3.125
  UTOPIA.STOR_HYDRO.ELC.2.(1990*2010)  1.3889
  UTOPIA.DIESEL_GEN.DSL.1.(1990*2010)  3.4
  UTOPIA.RHE.ELC.1.(1990*2010)  1
  UTOPIA.RHO.DSL.1.(1990*2010)  1.428571
  UTOPIA.RL1.ELC.1.(1990*2010)  1
  UTOPIA.SRE.OIL.1.(1990*2010)  1
  UTOPIA.TXD.DSL.1.(1990*2010)  1
  UTOPIA.TXE.ELC.1.(1990*2010)  1
  UTOPIA.TXG.GSL.1.(1990*2010)  1
/;

parameter OutputActivityRatio(r,t,f,m,y) /
  UTOPIA.COAL.ELC.1.(1990*2010)  1
  UTOPIA.NUCLEAR.ELC.1.(1990*2010)  1
  UTOPIA.HYDRO.ELC.1.(1990*2010)  1
  UTOPIA.STOR_HYDRO.ELC.1.(1990*2010)  1
  UTOPIA.DIESEL_GEN.ELC.1.(1990*2010)  1
  UTOPIA.IMPDSL1.DSL.1.(1990*2010)  1
  UTOPIA.IMPGSL1.GSL.1.(1990*2010)  1
  UTOPIA.IMPHCO1.HCO.1.(1990*2010)  1
  UTOPIA.IMPOIL1.OIL.1.(1990*2010)  1
  UTOPIA.IMPURN1.URN.1.(1990*2010)  1
  UTOPIA.RHE.RH.1.(1990*2010)  1
  UTOPIA.RHO.RH.1.(1990*2010)  1
  UTOPIA.RIV.HYD.1.(1990*2010)  1
  UTOPIA.RL1.RL.1.(1990*2010)  1
  UTOPIA.SRE.DSL.1.(1990*2010)  .7
  UTOPIA.SRE.GSL.1.(1990*2010)  .3
  UTOPIA.TXD.TX.1.(1990*2010)  1
  UTOPIA.TXE.TX.1.(1990*2010)  1
  UTOPIA.TXG.TX.1.(1990*2010)  1
/;

# By default, assume for imported secondary fuels the same efficiency of the internal refineries
InputActivityRatio(r,'IMPDSL1','OIL',m,y)$(not OutputActivityRatio(r,'SRE','DSL',m,y) eq 0) = 1/OutputActivityRatio(r,'SRE','DSL',m,y); 
InputActivityRatio(r,'IMPGSL1','OIL',m,y)$(not OutputActivityRatio(r,'SRE','GSL',m,y) eq 0) = 1/OutputActivityRatio(r,'SRE','GSL',m,y); 

*------------------------------------------------------------------------	
* Parameters - Technology costs       
*------------------------------------------------------------------------

parameter CapitalCost /
  UTOPIA.COAL.1990  1400
  UTOPIA.COAL.1991  1390
  UTOPIA.COAL.1992  1380
  UTOPIA.COAL.1993  1370
  UTOPIA.COAL.1994  1360
  UTOPIA.COAL.1995  1350
  UTOPIA.COAL.1996  1340
  UTOPIA.COAL.1997  1330
  UTOPIA.COAL.1998  1320
  UTOPIA.COAL.1999  1310
  UTOPIA.COAL.2000  1300
  UTOPIA.COAL.2001  1290
  UTOPIA.COAL.2002  1280
  UTOPIA.COAL.2003  1270
  UTOPIA.COAL.2004  1260
  UTOPIA.COAL.2005  1250
  UTOPIA.COAL.2006  1240
  UTOPIA.COAL.2007  1230
  UTOPIA.COAL.2008  1220
  UTOPIA.COAL.2009  1210
  UTOPIA.COAL.2010  1200
  UTOPIA.NUCLEAR.(1990*2010)  5000
  UTOPIA.HYDRO.(1990*2010)  3000
  UTOPIA.STOR_HYDRO.(1990*2010)  900
  UTOPIA.DIESEL_GEN.(1990*2010)  1000
  UTOPIA.IMPDSL1.(1990*2010)  0
  UTOPIA.IMPGSL1.(1990*2010)  0
  UTOPIA.IMPHCO1.(1990*2010)  0
  UTOPIA.IMPOIL1.(1990*2010)  0
  UTOPIA.IMPURN1.(1990*2010)  0
  UTOPIA.RHE.(1990*2010)  90
  UTOPIA.RHO.(1990*2010)  100
  UTOPIA.RIV.(1990*2010)  0
  UTOPIA.RL1.(1990*2010)  0
  UTOPIA.SRE.(1990*2010)  100
  UTOPIA.TXD.(1990*2010)  1044
  UTOPIA.TXE.1990  2000
  UTOPIA.TXE.1991  1975
  UTOPIA.TXE.1992  1950
  UTOPIA.TXE.1993  1925
  UTOPIA.TXE.1994  1900
  UTOPIA.TXE.1995  1875
  UTOPIA.TXE.1996  1850
  UTOPIA.TXE.1997  1825
  UTOPIA.TXE.1998  1800
  UTOPIA.TXE.1999  1775
  UTOPIA.TXE.2000  1750
  UTOPIA.TXE.2001  1725
  UTOPIA.TXE.2002  1700
  UTOPIA.TXE.2003  1675
  UTOPIA.TXE.2004  1650
  UTOPIA.TXE.2005  1625
  UTOPIA.TXE.2006  1600
  UTOPIA.TXE.2007  1575
  UTOPIA.TXE.2008  1550
  UTOPIA.TXE.2009  1525
  UTOPIA.TXE.2010  1500
  UTOPIA.TXG.(1990*2010)  1044
/;

parameter VariableCost(r,t,m,y) /
  UTOPIA.COAL.1.(1990*2010)  .3
  UTOPIA.NUCLEAR.1.(1990*2010)  1.5
  UTOPIA.DIESEL_GEN.1.(1990*2010)  .4
  UTOPIA.IMPDSL1.1.(1990*2010)  10
  UTOPIA.IMPGSL1.1.(1990*2010)  15
  UTOPIA.IMPHCO1.1.(1990*2010)  2
  UTOPIA.IMPOIL1.1.(1990*2010)  8
  UTOPIA.IMPURN1.1.(1990*2010)  2
  UTOPIA.SRE.1.(1990*2010)  10
/;
VariableCost(r,t,m,y)$(VariableCost(r,t,m,y) = 0) = 1e-5;

parameter FixedCost /
  UTOPIA.COAL.(1990*2010)  40
  UTOPIA.NUCLEAR.(1990*2010)  500
  UTOPIA.HYDRO.(1990*2010)  75
  UTOPIA.STOR_HYDRO.(1990*2010)  30
  UTOPIA.DIESEL_GEN.(1990*2010)  30
  UTOPIA.RHO.(1990*2010)  1
  UTOPIA.RL1.(1990*2010)  9.46
  UTOPIA.TXD.(1990*2010)  52
  UTOPIA.TXE.(1990*2010)  100
  UTOPIA.TXG.(1990*2010)  48
/;


*------------------------------------------------------------------------	
* Parameters - Storage       
*------------------------------------------------------------------------

parameter TechnologyToStorage(r,m,t,s) /
  UTOPIA.2.STOR_HYDRO.DAM  1
/;

parameter TechnologyFromStorage(r,m,t,s) /
  UTOPIA.1.STOR_HYDRO.DAM  1
/;

StorageLevelStart(r,s) = 999;

StorageMaxChargeRate(r,s) = 99;

StorageMaxDischargeRate(r,s) = 99;

MinStorageCharge(r,s,y) = 0;

OperationalLifeStorage(r,s) = 99;

CapitalCostStorage(r,s,y) = 0;

ResidualStorageCapacity(r,s,y) = 999;



*------------------------------------------------------------------------	
* Parameters - Capacity and investment constraints       
*------------------------------------------------------------------------

CapacityOfOneTechnologyUnit(r,t,y) = 0;

parameter TotalAnnualMaxCapacity /
  UTOPIA.HYDRO.1990  .1301
  UTOPIA.HYDRO.1991  .1401
  UTOPIA.HYDRO.1992  .1401
  UTOPIA.HYDRO.1993  .1501
  UTOPIA.HYDRO.1994  .1501
  UTOPIA.HYDRO.1995  .1501
  UTOPIA.HYDRO.1996  .1601
  UTOPIA.HYDRO.1997  .1601
  UTOPIA.HYDRO.1998  .1601
  UTOPIA.HYDRO.1999  .1601
  UTOPIA.HYDRO.2000  .1701
  UTOPIA.HYDRO.2001  .201
  UTOPIA.HYDRO.2002  .201
  UTOPIA.HYDRO.2003  .201
  UTOPIA.HYDRO.2004  .201
  UTOPIA.HYDRO.2005  .201
  UTOPIA.HYDRO.2006  .201
  UTOPIA.HYDRO.2007  .201
  UTOPIA.HYDRO.2008  .201
  UTOPIA.HYDRO.2009  .201
  UTOPIA.HYDRO.2010  .2101
  UTOPIA.STOR_HYDRO.(1990*2010)  3
  UTOPIA.RHE.1990  EPS
  UTOPIA.RHE.1991  EPS
  UTOPIA.RHE.1992  EPS
  UTOPIA.RHE.1993  EPS
  UTOPIA.RHE.1994  EPS
  UTOPIA.RHE.1995  EPS
  UTOPIA.RHE.1996  EPS
  UTOPIA.RHE.1997  EPS
  UTOPIA.RHE.1998  EPS
  UTOPIA.RHE.1999  EPS
  UTOPIA.RHE.2000  99999
  UTOPIA.RHE.2001  99999
  UTOPIA.RHE.2002  99999
  UTOPIA.RHE.2003  99999
  UTOPIA.RHE.2004  99999
  UTOPIA.RHE.2005  99999
  UTOPIA.RHE.2006  99999
  UTOPIA.RHE.2007  99999
  UTOPIA.RHE.2008  99999
  UTOPIA.RHE.2009  99999
  UTOPIA.RHE.2010  99999
  UTOPIA.SRE.1990  .1001
  UTOPIA.SRE.1991  .1001
  UTOPIA.SRE.1992  .1001
  UTOPIA.SRE.1993  .1001
  UTOPIA.SRE.1994  .1001
  UTOPIA.SRE.1995  .1001
  UTOPIA.SRE.1996  .1001
  UTOPIA.SRE.1997  .1001
  UTOPIA.SRE.1998  .1001
  UTOPIA.SRE.1999  .1001
  UTOPIA.SRE.2000  99999
  UTOPIA.SRE.2001  99999
  UTOPIA.SRE.2002  99999
  UTOPIA.SRE.2003  99999
  UTOPIA.SRE.2004  99999
  UTOPIA.SRE.2005  99999
  UTOPIA.SRE.2006  99999
  UTOPIA.SRE.2007  99999
  UTOPIA.SRE.2008  99999
  UTOPIA.SRE.2009  99999
  UTOPIA.SRE.2010  99999
  UTOPIA.TXE.1990  EPS
  UTOPIA.TXE.1991  .4
  UTOPIA.TXE.1992  .8
  UTOPIA.TXE.1993  1.2
  UTOPIA.TXE.1994  1.6
  UTOPIA.TXE.1995  2
  UTOPIA.TXE.1996  2.4
  UTOPIA.TXE.1997  2.8
  UTOPIA.TXE.1998  3.2
  UTOPIA.TXE.1999  3.6
  UTOPIA.TXE.2000  4
  UTOPIA.TXE.2001  4.6
  UTOPIA.TXE.2002  5.2
  UTOPIA.TXE.2003  5.8
  UTOPIA.TXE.2004  6.4
  UTOPIA.TXE.2005  7
  UTOPIA.TXE.2006  7.6
  UTOPIA.TXE.2007  8.2
  UTOPIA.TXE.2008  8.8
  UTOPIA.TXE.2009  9.4
  UTOPIA.TXE.2010  10
/;
TotalAnnualMaxCapacity(r,t,y)$(TotalAnnualMaxCapacity(r,t,y) = 0) = 99999;
TotalAnnualMaxCapacity(r,'TXE','1990') = 0;
TotalAnnualMaxCapacity(r,'RHE','1990') = 0;

parameter TotalAnnualMinCapacity(r,t,y) /
  UTOPIA.HYDRO.1990  .13
  UTOPIA.HYDRO.1991  .14
  UTOPIA.HYDRO.1992  .14
  UTOPIA.HYDRO.1993  .15
  UTOPIA.HYDRO.1994  .15
  UTOPIA.HYDRO.1995  .15
  UTOPIA.HYDRO.1996  .16
  UTOPIA.HYDRO.1997  .16
  UTOPIA.HYDRO.1998  .16
  UTOPIA.HYDRO.1999  .16
  UTOPIA.HYDRO.2000  .17
  UTOPIA.HYDRO.2001  .2
  UTOPIA.HYDRO.2002  .2
  UTOPIA.HYDRO.2003  .2
  UTOPIA.HYDRO.2004  .2
  UTOPIA.HYDRO.2005  .2
  UTOPIA.HYDRO.2006  .2
  UTOPIA.HYDRO.2007  .2
  UTOPIA.HYDRO.2008  .2
  UTOPIA.HYDRO.2009  .2
  UTOPIA.HYDRO.2010  .21
  UTOPIA.SRE.1990  .1
  UTOPIA.SRE.1991  .1
  UTOPIA.SRE.1992  .1
  UTOPIA.SRE.1993  .1
  UTOPIA.SRE.1994  .1
  UTOPIA.SRE.1995  .1
  UTOPIA.SRE.1996  .1
  UTOPIA.SRE.1997  .1
  UTOPIA.SRE.1998  .1
  UTOPIA.SRE.1999  .1
  UTOPIA.SRE.2000  0
  UTOPIA.SRE.2001  0
  UTOPIA.SRE.2002  0
  UTOPIA.SRE.2003  0
  UTOPIA.SRE.2004  0
  UTOPIA.SRE.2005  0
  UTOPIA.SRE.2006  0
  UTOPIA.SRE.2007  0
  UTOPIA.SRE.2008  0
  UTOPIA.SRE.2009  0
  UTOPIA.SRE.2010  0
/;

TotalAnnualMaxCapacityInvestment(r,t,y) = 99999;

TotalAnnualMinCapacityInvestment(r,t,y) = 0;


*------------------------------------------------------------------------	
* Parameters - Activity constraints       
*------------------------------------------------------------------------

TotalTechnologyAnnualActivityUpperLimit(r,t,y) = 99999;

TotalTechnologyAnnualActivityLowerLimit(r,t,y) = 0;

TotalTechnologyModelPeriodActivityUpperLimit(r,t) = 99999;

TotalTechnologyModelPeriodActivityLowerLimit(r,t) = 0;


*------------------------------------------------------------------------	
* Parameters - Reserve margin
*-----------------------------------------------------------------------

parameter ReserveMarginTagTechnology(r,t,y) /
  UTOPIA.COAL.(1990*2010)  1
  UTOPIA.NUCLEAR.(1990*2010)  1
  UTOPIA.HYDRO.(1990*2010)  1
  UTOPIA.STOR_HYDRO.(1990*2010)  1
  UTOPIA.DIESEL_GEN.(1990*2010)  1
/;

parameter ReserveMarginTagFuel(r,f,y) /
  UTOPIA.ELC.(1990*2010)  1
/;

parameter ReserveMargin(r,y) /
  UTOPIA.(1990*2010)  1.18
/;


*------------------------------------------------------------------------	
* Parameters - RE Generation Target       
*------------------------------------------------------------------------

RETagTechnology(r,t,y) = 0;

RETagFuel(r,f,y) = 0;

REMinProductionTarget(r,y) = 0;


*------------------------------------------------------------------------	
* Parameters - Emissions       
*------------------------------------------------------------------------

parameter EmissionActivityRatio(r,t,e,m,y) /
  UTOPIA.IMPDSL1.CO2.1.(1990*2010)  .075
  UTOPIA.IMPGSL1.CO2.1.(1990*2010)  .075
  UTOPIA.IMPHCO1.CO2.1.(1990*2010)  .089
  UTOPIA.IMPOIL1.CO2.1.(1990*2010)  .075
  UTOPIA.TXD.NOX.1.(1990*2010)  1
  UTOPIA.TXG.NOX.1.(1990*2010)  1
/;

EmissionsPenalty(r,e,y) = 0;

AnnualExogenousEmission(r,e,y) = 0;

AnnualEmissionLimit(r,e,y) = 9999;

ModelPeriodExogenousEmission(r,e) = 0;

ModelPeriodEmissionLimit(r,e) = 9999;