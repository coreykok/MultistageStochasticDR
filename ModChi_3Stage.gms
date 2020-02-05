set i  conventional units    / i1 * i3 /;
set j  DL units    / j1 * j2 /;
set s2 scenarios time step 2 / 1 * 3 /;
set s3 scenarios time step 3 / 1 * 3 /;
set t  time /1 * 3/;
set p_full index of probability measures that are on the border of chi squared test / p1 * p10 /;
set Kset2(p_full);
set Kset3(p_full);
set k2(s2) scenarios time step 2 / 1 * 3 /;
set k3(s3) scenarios time step 3 / 1 * 3 /;
Kset2(p_full) = no;
Kset3(p_full) = no;


alias (s2,w2);
alias (s3,w3);

set t1(t) /1/;
set t2(t) /2/;
set t3(t) /3/;

* Parameters used directly in formulation
parameters
 C_Con_DA(i,t)       Day Ahead cost of electricity
 C_Con_up(i,t)   conventional up-reg cost
 C_Con_dn(i,t)   conventional down-reg cost
 P_Con_up(i,t)   conventional up-reg limit
 P_Con_dn(i,t)   conventional down-reg limit
 Dem(t)          Demand
 Wind_1(t)               Wind Data t1
 WindData_2(t,s2,*)      Wind Data t2
 WindData_3(t,s2,s3,*)   Wind Data t3

 Wind_2(t,s2)    Wind t2
 Wind_3(t,s2,s3) Wind t3

 p_hat_2(t,s2)    Wind t2
 p_hat_3(t,s2,s3) Wind t3

 Prob(s2,s3)    Probability of trajectory

 C_DL_dn(j,t)   Cost for DL unit to consume
 C_DL_ct(j,t)   Cost for DL unit to be curtailed
 R_up(j,t)      Ramping up limit for DL unit
 R_dn(j,t)      Ramping dn limit for DL unit
 P_DL_dn(j,t)   Limit on DL unit consumption
 P_DL_ct(j,t)   Limit on DL unit curtailment
 E_Req(j,t)     Energy requirement for DL unit
 E_Cap(j)       Maximum energy that can be stored in DL unit
;

* Parameters used to update risk set
parameters
 root_term2(s2)
 root_term3(s3)
 crit_r2(s2)
 crit_r3(s3)
;
scalars
 index
 m
 k
 Q_bar
 s
 ewl
;
scalar r radius of ambiguity set /0.1/;


$call csv2gdx C_Con_DA.csv id=C_Con_DA   fieldSep=comma index=1,2  values=3 useHeader=y
$call csv2gdx C_Con_up.csv id=C_Con_up   fieldSep=comma index=1,2  values=3 useHeader=y
$call csv2gdx C_Con_dn.csv id=C_Con_dn   fieldSep=comma index=1,2  values=3 useHeader=y
$call csv2gdx P_Con_up.csv id=P_Con_up   fieldSep=comma index=1,2  values=3 useHeader=y
$call csv2gdx P_Con_dn.csv id=P_Con_dn   fieldSep=comma index=1,2  values=3 useHeader=y
$call csv2gdx Dem.csv      id=Dem        fieldSep=comma index=1    values=2 useHeader=y
$call csv2gdx Wind_1.csv   id=Wind_1     fieldSep=comma index=1    values=2 useHeader=y
$call csv2gdx Wind_2.csv   id=WindData_2 fieldSep=comma index=1,2  values=3,4 useHeader=y
$call csv2gdx Wind_3.csv   id=WindData_3 fieldSep=comma index=1..3 values=4,5 useHeader=y

$call csv2gdx C_DL_dn.csv id=C_DL_dn fieldSep=comma index=1,2 values=3 useHeader=y
$call csv2gdx C_DL_ct.csv id=C_DL_ct fieldSep=comma index=1,2 values=3 useHeader=y
$call csv2gdx R_up.csv    id=R_up    fieldSep=comma index=1,2 values=3 useHeader=y
$call csv2gdx R_dn.csv    id=R_dn    fieldSep=comma index=1,2 values=3 useHeader=y
$call csv2gdx P_DL_dn.csv id=P_DL_dn fieldSep=comma index=1,2 values=3 useHeader=y
$call csv2gdx P_DL_ct.csv id=P_DL_ct fieldSep=comma index=1,2 values=3 useHeader=y
$call csv2gdx E_Req.csv   id=E_Req   fieldSep=comma index=1,2 values=3 useHeader=y
$call csv2gdx E_Cap.csv   id=E_Cap   fieldSep=comma index=1   values=2 useHeader=y



$gdxin C_Con_DA
$load C_Con_DA
$gdxin
$gdxin C_Con_up
$load C_Con_up
$gdxin
$gdxin C_Con_dn
$load C_Con_dn
$gdxin
$gdxin P_Con_up
$load P_Con_up
$gdxin
$gdxin P_Con_dn
$load P_Con_dn
$gdxin
$gdxin Dem
$load Dem
$gdxin
$gdxin Wind_1
$load Wind_1
$gdxin
$gdxin Wind_2
$load WindData_2
$gdxin
$gdxin Wind_3
$load WindData_3
$gdxin
$gdxin C_DL_dn
$load C_DL_dn
$gdxin
$gdxin C_DL_ct
$load C_DL_ct
$gdxin
$gdxin R_up
$load R_up
$gdxin
$gdxin R_dn
$load R_dn
$gdxin
$gdxin P_DL_dn
$load P_DL_dn
$gdxin
$gdxin P_DL_ct
$load P_DL_ct
$gdxin
$gdxin E_Req
$load E_Req
$gdxin
$gdxin E_Cap
$load E_Cap
$gdxin




p_hat_2(t,s2)    = WindData_2(t,s2,'Prob_2');
p_hat_3(t,s2,s3) = WindData_3(t,s2,s3,'Prob_3');
parameter lambda Weight on expected cost /0.5/;
parameter alpha Weight on expected cost /0.66666/ ;


Wind_2(t,s2)    = WindData_2(t,s2,'Wind_2');
Wind_3(t,s2,s3) = WindData_3(t,s2,s3,'Wind_3');

parameter p_2(p_full,s2);
parameter p_3(p_full,s2,s3);


positive variables
 c_DA(i,t)               Day ahead up-reg

 c_up_1(i,t)             conventional up-reg t1
 c_up_2(i,t,s2)          conventional up-reg t2
 c_up_3(i,t,s2,s3)       conventional up-reg t3

 c_dn_1(i,t)             conventional down-reg t1
 c_dn_2(i,t,s2)          conventional down-reg t2
 c_dn_3(i,t,s2,s3)       conventional down-reg t3

 d_dn_1(j,t)             deferrable consumption t1
 d_dn_2(j,t,s2)          deferrable consumption t2
 d_dn_3(j,t,s2,s3)       deferrable consumption t3

 d_ct_1(j,t)             deferrable curtailment t1
 d_ct_2(j,t,s2)          deferrable curtailment t2
 d_ct_3(j,t,s2,s3)       deferrable curtailment t3

 e_DL_1(j,t)             energy state of DL t1
 e_DL_2(j,t,s2)          energy state of DL t2
 e_DL_3(j,t,s2,s3)       energy state of DL t3
;

variables
 TC1              Total cost stage 1 plus expected cost following
 TC2(s2)          Total cost stage 2 plus expected cost following
 TC3(s2,s3)       Total cost stage 3

 BC1              Balancing cost stage 1
 BC2(s2)          Balancing cost stage 2
 BC3(s2,s3)       Balancing cost stage 3
;

variables
 VaR_1            Value at risk stage 1
 VaR_2(s2)        Value at risk stage 2 given scenario outcome
;

positive variables
 Pr2(s2)         risk adjusted probability stage 1
 Pr3(s2,s3)      risk adjusted probability stage 2
;

equations
 TotalCost1(p_full)         Balancing cost stage 1 plus risk adjusted cost following
 TotalCost2(s2,p_full)      Balancing cost stage 2 plus risk adjusted cost following
 TotalCost3(s2,s3)          Balancing cost stage 3

 BalCost1         Balancing cost stage 1
 BalCost2(s2)     Balancing cost stage 2
 BalCost3(s2,s3)  Balancing cost stage 3

 PBal_1(t)        Balancing requirement t1
 PBal_2(t,s2)     Balancing requirement t2
 PBal_3(t,s2,s3)  Balancing requirement t3

 P_Con_up_1_Limit(i,t)       Real Time up reg limit t1
 P_Con_up_2_Limit(i,t,s2)    Real Time up reg limit t2
 P_Con_up_3_Limit(i,t,s2,s3) Real Time up reg limit t3

 P_Con_dn_1_Limit(i,t)       Real Time up reg limit t1
 P_Con_dn_2_Limit(i,t,s2)    Real Time up reg limit t2
 P_Con_dn_3_Limit(i,t,s2,s3) Real Time up reg limit t3

 Energy_Requirement_1(j,t)       DL Energy requirement t1
 Energy_Requirement_2(j,t,s2)    DL Energy requirement t2
 Energy_Requirement_3(j,t,s2,s3) DL Energy requirement t3

 Energy_State_1(j,t)             DL Energy state t1
 Energy_State_2(j,t,s2)          DL Energy state t2
 Energy_State_3(j,t,s2,s3)       DL Energy state t3

 Ramp_up_Limit_1(j,t)            Ramp up limit t1
 Ramp_up_Limit_2(j,t,s2)         Ramp up limit t2
 Ramp_up_Limit_3(j,t,s2,s3)      Ramp up limit t3

 Ramp_dn_Limit_1(j,t)            Ramp up limit t1
 Ramp_dn_Limit_2(j,t,s2)         Ramp dn limit t2
 Ramp_dn_Limit_3(j,t,s2,s3)      Ramp dn limit t3
;

TotalCost1(Kset2)..           TC1 =g= BC1     + sum((t2(t),s2), p_2(Kset2,s2) * TC2(s2));
TotalCost2(s2,Kset3)..    TC2(s2) =g= BC2(s2) + sum((t3(t),s3), p_3(Kset3,s2,s3) * TC3(s2,s3)) ;
TotalCost3(s2,s3)..     TC3(s2,s3) =e= BC3(s2,s3);

BalCost1..         BC1 =e= sum(t1(t),
                                 sum(i,
                                         C_Con_DA(i,t) * c_DA(i,t) +
                                         C_Con_up(i,t) * c_up_1(i,t) +
                                         C_Con_dn(i,t) * c_dn_1(i,t)
                                 ) +
                                 sum(j,
                                         C_DL_dn(j,t)  * d_dn_1(j,t) +
                                         C_DL_ct(j,t)  * d_ct_1(j,t)
                                 )
                           );

BalCost2(s2)..     BC2(s2) =e= sum(t2(t),
                                 sum(i,
                                         C_Con_DA(i,t) * c_DA(i,t) +
                                         C_Con_up(i,t) * c_up_2(i,t,s2) +
                                         C_Con_dn(i,t) * c_dn_2(i,t,s2)
                                 ) +
                                 sum(j,
                                         C_DL_dn(j,t)  * d_dn_2(j,t,s2) +
                                         C_DL_ct(j,t)  * d_ct_2(j,t,s2)
                                 )
                               );
BalCost3(s2,s3)..  BC3(s2,s3) =e=  sum(t3(t),
                                   sum(i,
                                         C_Con_DA(i,t) * c_DA(i,t) +
                                         C_Con_up(i,t) * c_up_3(i,t,s2,s3) +
                                         C_Con_dn(i,t) * c_dn_3(i,t,s2,s3)
                                   ) +
                                   sum(j,
                                         C_DL_dn(j,t)  * d_dn_3(j,t,s2,s3) +
                                         C_DL_ct(j,t)  * d_ct_3(j,t,s2,s3)
                                   )
                                  );

PBal_1(t1(t)).. sum(i, c_DA(i,t) + c_up_1(i,t) - c_dn_1(i,t)) - sum(j, d_dn_1(j,t)) =e= Dem(t) - Wind_1(t);

PBal_2(t2(t),s2).. sum(i, c_DA(i,t) + c_up_2(i,t,s2) - c_dn_2(i,t,s2)) - sum(j, d_dn_2(j,t,s2)) =e= Dem(t) - Wind_2(t,s2);

PBal_3(t3(t),s2,s3).. sum(i, c_DA(i,t) + c_up_3(i,t,s2,s3) - c_dn_3(i,t,s2,s3)) - sum(j, d_dn_3(j,t,s2,s3)) =e= Dem(t) - Wind_3(t,s2,s3);


P_Con_up_1_Limit(i,t1(t))..       c_up_1(i,t)       =l= P_Con_up(i,t) - c_DA(i,t);
P_Con_up_2_Limit(i,t2(t),s2)..    c_up_2(i,t,s2)    =l= P_Con_up(i,t) - c_DA(i,t);
P_Con_up_3_Limit(i,t3(t),s2,s3).. c_up_3(i,t,s2,s3) =l= P_Con_up(i,t) - c_DA(i,t);

P_Con_dn_1_Limit(i,t1(t))..       c_dn_1(i,t)       =l= P_Con_dn(i,t) + c_DA(i,t);
P_Con_dn_2_Limit(i,t2(t),s2)..    c_dn_2(i,t,s2)    =l= P_Con_dn(i,t) + c_DA(i,t);
P_Con_dn_3_Limit(i,t3(t),s2,s3).. c_dn_3(i,t,s2,s3) =l= P_Con_dn(i,t) + c_DA(i,t);

Energy_Requirement_1(j,t1(t))..       e_DL_1(j,t)       =g= E_Req(j,t);
Energy_Requirement_2(j,t2(t),s2)..    e_DL_2(j,t,s2)    =g= E_Req(j,t);
Energy_Requirement_3(j,t3(t),s2,s3).. e_DL_3(j,t,s2,s3) =g= E_Req(j,t);

Energy_State_1(j,t1(t))..       e_DL_1(j,t)       =e= d_dn_1(j,t) + d_ct_1(j,t);
Energy_State_2(j,t2(t),s2)..    e_DL_2(j,t,s2)    =e= e_DL_1(j,t-1) + d_dn_2(j,t,s2) + d_ct_2(j,t,s2);
Energy_State_3(j,t3(t),s2,s3).. e_DL_3(j,t,s2,s3) =e= e_DL_2(j,t-1,s2) + d_dn_3(j,t,s2,s3) + d_ct_3(j,t,s2,s3);

Ramp_up_Limit_1(j,t1(t))..        d_dn_1(j,t)                          =l= R_up(j,t);
Ramp_up_Limit_2(j,t2(t),s2)..     d_dn_2(j,t,s2)    - d_dn_1(j,t-1)    =l= R_up(j,t);
Ramp_up_Limit_3(j,t3(t),s2,s3)..  d_dn_3(j,t,s2,s3) - d_dn_2(j,t-1,s2) =l= R_up(j,t);

Ramp_dn_Limit_1(j,t1(t))..                         - d_dn_1(j,t)         =l= R_dn(j,t);
Ramp_dn_Limit_2(j,t2(t),s2)..     d_dn_1(j,t-1)    - d_dn_2(j,t,s2)    =l= R_dn(j,t);
Ramp_dn_Limit_3(j,t3(t),s2,s3)..  d_dn_2(j,t-1,s2) - d_dn_3(j,t,s2,s3) =l= R_dn(j,t);

model ConvFlex /
 TotalCost1, TotalCost2, TotalCost3,
 BalCost1, BalCost2, BalCost3,
 PBal_1, PBal_2, PBal_3,
 P_Con_up_1_Limit, P_Con_up_2_Limit, P_Con_up_3_Limit,
 P_Con_dn_1_Limit, P_Con_dn_2_Limit, P_Con_dn_3_Limit,
 Energy_Requirement_1, Energy_Requirement_2, Energy_Requirement_3,
 Energy_State_1, Energy_State_2, Energy_State_3,
 Ramp_up_Limit_1, Ramp_up_Limit_2, Ramp_up_Limit_3,
 Ramp_dn_Limit_1, Ramp_dn_Limit_2, Ramp_dn_Limit_3
 /;

*Solver options
FILE OPT cplex OPTION FILE /cplex.opt/
put opt;
put 'threads 0'/;
putclose;

Option Limcol = 10000;
Option Limrow = 10000;
Option optcr = 0
Option optca = 0

OPTION RESLIM = 50000;

c_DA.fx('i1',t) = 0.5;
c_DA.fx('i2',t) = 1;
c_DA.fx('i3',t) = 0;


Kset2('p1') = yes;
Kset3('p1') = yes;
p_2('p1',s2)    = p_hat_2('2',s2);
p_3('p1',s2,s3) = p_hat_3('3',s2,s3);
solve ConvFlex minimizing TC1 using lp;



loop(p_full,
Kset2(p_full) = yes;
Kset3(p_full) = yes;
$include GetModChi2.gms
$include GetModChi3.gms
solve ConvFlex minimizing TC1 using lp;
display s,p_2;
);

display         TC1.l, TC2.l, TC3.l;
display p_2,p_3;
$exit

* Exported parameters
parameters
  p_c_DA(i,t)
  p_c_up_1(i,t)
  p_c_up_2(i,t,s2)
  p_c_up_3(i,t,s2,s3)
  p_c_dn_1(i,t)
  p_c_dn_2(i,t,s2)
  p_c_dn_3(i,t,s2,s3)
  cost_DA(i,t,s2,s3)
  cost_up(i,t,s2,s3)
  cost_dn(i,t,s2,s3)
  p_d_dn_1(j,t)
  p_d_dn_2(j,t,s2)
  p_d_dn_3(j,t,s2,s3)
  p_d_ct_1(j,t)
  p_d_ct_2(j,t,s2)
  p_d_ct_3(j,t,s2,s3)
  cost_DL_dn(j,t,s2,s3)
  cost_DL_ct(j,t,s2,s3)
;

p_c_DA(i,t)         = c_DA.l(i,t);
p_c_up_1(i,t)       = c_up_1.l(i,t);
p_c_up_2(i,t,s2)    = c_up_2.l(i,t,s2);
p_c_up_3(i,t,s2,s3) = c_up_3.l(i,t,s2,s3);
p_c_dn_1(i,t)       = c_dn_1.l(i,t);
p_c_dn_2(i,t,s2)    = c_dn_2.l(i,t,s2);
p_c_dn_3(i,t,s2,s3) = c_dn_3.l(i,t,s2,s3);
p_d_dn_1(j,t)       = d_dn_1.l(j,t);
p_d_dn_2(j,t,s2)    = d_dn_2.l(j,t,s2);
p_d_dn_3(j,t,s2,s3) = d_dn_3.l(j,t,s2,s3);
p_d_ct_1(j,t)       = d_ct_1.l(j,t);
p_d_ct_2(j,t,s2)    = d_ct_2.l(j,t,s2);
p_d_ct_3(j,t,s2,s3) = d_ct_3.l(j,t,s2,s3);

cost_DA(i,t,s2,s3)  = C_Con_DA(i,t) * c_DA.l(i,t);
cost_up(i,t,s2,s3)  = C_Con_up(i,t) * ( c_up_1.l(i,t) + c_up_2.l(i,t,s2) + c_up_3.l(i,t,s2,s3) );
cost_dn(i,t,s2,s3)  = C_Con_dn(i,t) * ( c_dn_1.l(i,t) + c_dn_2.l(i,t,s2) + c_dn_3.l(i,t,s2,s3) );
cost_DL_dn(j,t,s2,s3)  = C_DL_dn(j,t) * (d_dn_1.l(j,t) + d_dn_2.l(j,t,s2) + d_dn_3.l(j,t,s2,s3));
cost_DL_ct(j,t,s2,s3)  = C_DL_ct(j,t) * (d_ct_1.l(j,t) + d_ct_2.l(j,t,s2) + d_ct_3.l(j,t,s2,s3));


execute_unload 'OutputFile_DL_ConvMult_MC', p_c_DA,
                                      p_c_up_1, p_c_up_2, p_c_up_3,
                                      p_c_dn_1, p_c_dn_2, p_c_dn_3,
                                      p_d_dn_1, p_d_dn_2, p_d_dn_3,
                                      p_d_ct_1, p_d_ct_2, p_d_ct_3,
                                      cost_DA,
                                      cost_up, cost_dn,
                                      cost_DL_dn, cost_DL_ct,
                                      Dem, Wind_1, WindData_2, WindData_3;


