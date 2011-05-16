function [ plan ] = neuro_mk_exec_plan (execdefs, dag, params, resultsetidx)
    plan.def = execdefs;
    plan.dag = dag;
    plan.params = params;
    plan.resultsetidx = resultsetidx;