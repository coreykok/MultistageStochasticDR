{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "function DefineDRPolicy()\n",
    "#$(model_list[rsk])\n",
    "    DRPolicy = SDDP.LinearPolicyGraph(\n",
    "            stages = 6,\n",
    "            sense = :Min,\n",
    "            lower_bound = 0,\n",
    "            optimizer = with_optimizer(Gurobi.Optimizer, gurobi_env, OutputFlag = 0)\n",
    "    ) do subproblem, t\n",
    "\n",
    "        # Control Variables\n",
    "        @variables(subproblem, begin\n",
    "            0 <= d_ct[j = DEFERRABLE]    <= P_DL_ct[j, t]\n",
    "            0 <= c_up[i = CONVENTIONAL]  <= P_Con_up[i, t]\n",
    "            0 <= c_dn[i = CONVENTIONAL]  <= P_Con_dn[i, t]\n",
    "            W\n",
    "        end)\n",
    "        @variable(subproblem,\n",
    "            0 <= e_DL[j = DEFERRABLE] <= E_Cap[j], SDDP.State, initial_value = 0.0\n",
    "        )\n",
    "        @variable(subproblem,\n",
    "            0 <= d_dn[j = DEFERRABLE] <= P_DL_dn[j, t], SDDP.State, initial_value = 0.0\n",
    "        )\n",
    "        @constraint(subproblem,\n",
    "            sum(c_up[i] - c_dn[i] for i in CONVENTIONAL) -\n",
    "            sum(d_dn[j].out for j in DEFERRABLE)  == Demand[t] - W\n",
    "        )\n",
    "        @constraints(subproblem, begin\n",
    "            [j = DEFERRABLE], e_DL[j].out >= E_Req[j, t]\n",
    "            [j = DEFERRABLE], e_DL[j].out == e_DL[j].in + d_dn[j].out + d_ct[j]\n",
    "            [j = DEFERRABLE], d_dn[j].out - d_dn[j].in <= R_up[j,t]\n",
    "            [j = DEFERRABLE], d_dn[j].in - d_dn[j].out <= R_dn[j,t]\n",
    "        end)\n",
    "    \n",
    "        SDDP.parameterize(subproblem, Ω, probability) do ω\n",
    "            JuMP.fix(W, ω.Wind)\n",
    "            @stageobjective(subproblem,\n",
    "                sum(C_Con_up[i, t] * c_up[i] + C_Con_dn[i, t] * c_dn[i] for i in CONVENTIONAL) +\n",
    "                sum(C_DL_dn[j, t] * d_dn[j].out + C_DL_ct[j, t] * d_ct[j] for j in DEFERRABLE)\n",
    "            )\n",
    "        end\n",
    "    end\n",
    "    return DRPolicy\n",
    "end"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Julia 1.1.0",
   "language": "julia",
   "name": "julia-1.1"
  },
  "language_info": {
   "file_extension": ".jl",
   "mimetype": "application/julia",
   "name": "julia",
   "version": "1.1.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
