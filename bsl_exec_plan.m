function [ plan ] = bsl_exec_plan (execdefs, dag, params)
    plan.def = execdefs;
    plan.dag = dag;
    plan.params = params;