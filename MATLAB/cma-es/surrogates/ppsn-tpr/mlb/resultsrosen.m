% script for plotting simulation results for rosenbrock function
warning off
clear all, close all

figure(1)
[g_c_2, f_c_2] = getstats('cleanrosen2',10);
semilogy(g_c_2, f_c_2,'k-'); hold on

[g_p4_2, f_p4_2] = getstats('p4rosen2', 10);
semilogy(g_p4_2, f_p4_2,'k:');

[g_p2_2, f_p2_2] = getstats('p2rosen2', 10);
semilogy(g_p2_2, f_p2_2,'k--');

[g_r1_2, f_r1_2] = getstats('r1rosen2', 10);
semilogy(g_r1_2, f_r1_2,'k-.');


figure(2)
[g_c_5, f_c_5] = getstats('cleanrosen5',10);
semilogy(g_c_5, f_c_5,'k-'); hold on

[g_p4_5, f_p4_5] = getstats('p4rosen5', 10);
semilogy(g_p4_5, f_p4_5,'k:');

[g_p2_5, f_p2_5] = getstats('p2rosen5', 10);
semilogy(g_p2_5, f_p2_5,'k--');

[g_r1_5, f_r1_5] = getstats('r1rosen5', 10);
semilogy(g_r1_5, f_r1_5,'k-.');



warning on