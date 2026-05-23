E = 21e4 #MPa= 210 GPa
nu = 0.3     #
gc = 2.7 #10 #2.7     #KJ/m2 = MPa.mm
l = 0.016    #mm

# ===== Frequency-driven timing (seconds) =====
f           = 1                     # Frequency [Hz]

umax = 0.0005
period      = ${fparse 1/f}        # Physical time per cycle [s]
cycles_per_step = 20               # How many cycles to advance per step
num_cycle = 38000
end_time    = ${fparse num_cycle * period/cycles_per_step} 
deltat      = 1 #${fparse cycles_per_step * period}   # Time step length (s)
#=========Hydrogen=============#
#N·mm=10^3 J
M_H        = 0.001008       # kg/mol Molar mass of hydrogen
rho_M      = 7.85e-6        # kg/mm^3 Steel density 

[GlobalParams]
  displacements = 'disp_x disp_y'
[]
[MultiApps]
  [./hyd]
    type = TransientMultiApp
    input_files = 'fatigue_H_C45.i'     # Hydrogen
    execute_on = TIMESTEP_END
  [../]
  [./crack]
    type = TransientMultiApp
    #input_files = 'fatigue_H_f_Cui1.i'     # PF
    input_files = 'fatigue_H_f_aniso45.i'     # PF
    execute_on = TIMESTEP_END
  [../]
[]

[Transfers]

########## PF -> Main ##########
  [./from_crack_d]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'd'
    variable = 'd'
    execute_on = TIMESTEP_END
  [../]

  [./from_current_fatigue]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'current_fatigue'
    variable = 'current_fatigue'
    execute_on = TIMESTEP_END
  [../]

  [./from_accumulate_fatigue]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'bar_alpha'
    variable = 'bar_alpha'
    execute_on = TIMESTEP_END
  [../]

  [./from_fatigue_function]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'f_alpha'
    variable = 'f_alpha'
    execute_on = TIMESTEP_END
  [../]

  [./from_kappa]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'kappa_op'
    variable = 'kappa_op'
    execute_on = TIMESTEP_END
  [../]

########## Main -> H ##########
  [./to_hyd_d]
    type = MultiAppProjectionTransfer      # 更稳妥；若网格完全一致，用 Copy 也行
    to_multi_app = hyd
    source_variable = d
    variable = d
    execute_on = TIMESTEP_END
  [../]

  [./to_hyd_sigma]
    type = MultiAppProjectionTransfer
    to_multi_app = hyd
    source_variable = sigma_h
    variable = sigma_h
    execute_on = TIMESTEP_END              # 显式写上
  [../]

########## H -> Main ##########
  [./from_hyd_C]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    from_multi_app = hyd
    source_variable = C
    variable = C
    execute_on = TIMESTEP_END
  [../]

########## Main -> PF ##########
  [./to_crack_disp_x]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    to_multi_app = 'crack'
    source_variable = 'disp_x'
    variable = 'disp_x'
    execute_on = TIMESTEP_BEGIN
  [../]
  [./to_crack_disp_y]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    to_multi_app = 'crack'
    source_variable = 'disp_y'
    variable = 'disp_y'
    execute_on = TIMESTEP_BEGIN
  [../]
  [./to_crack_CLA]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    to_multi_app = 'crack'
    source_variable = 'n_cycle'
    variable = 'n_cycle'
    execute_on = TIMESTEP_BEGIN
  [../]

  
  [./to_crack_C]
    type = MultiAppProjectionTransfer #MultiAppCopyTransfer
    to_multi_app = crack
    source_variable = C
    variable = C
    execute_on = TIMESTEP_BEGIN      # 用上一步的 C，避免强耦合
  [../]
[]


[Mesh]
  file = SENT13.inp
  uniform_refine = 0
  skip_partitioning = true
  construct_side_list_from_node_list=true
[]

[Physics/SolidMechanics/QuasiStatic]
  [./All]
    add_variables = true
    strain = FINITE
    incremental = true
    additional_generate_output = 'stress_xx stress_yy stress_xy'
    use_automatic_differentiation=false
    strain_base_name = uncracked
    decomposition_method = EigenSolution
  [../]
[../]


[AuxVariables]
# ---------- Hydrogen ---------- 
  [./sigma_h] family=MONOMIAL order=FIRST []
  [./C]       family=LAGRANGE order=FIRST []
  [./chi] family=MONOMIAL order=FIRST []
  [./C_ppm]
    family = LAGRANGE      # 如果 C 是节点变量（常见），就用 LAGRANGE
    order  = FIRST
  [../]
  [./chi_node]
    family = LAGRANGE
    order  = FIRST
  [../]
  [./r_d095]
    family = LAGRANGE
    order  = FIRST
  [../]
# ---------- Hydrogen ---------- 

  [./d]
  family = LAGRANGE
  order  = FIRST
  []
  #[./bounds_dummy]
  #[../]
  [./current_fatigue]
    order = CONSTANT
    family = MONOMIAL
  []
  [./bar_alpha]
    order = CONSTANT
    family = MONOMIAL
  []
  [./f_alpha]
    order = CONSTANT
    family = MONOMIAL
  []
  [./kappa_op]
    order = FIRST
    family = MONOMIAL
  []
  [./n_cycle]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./n_cycle_aux]
    type = FunctionAux
    variable = n_cycle
    function = current_cycle
    execute_on = TIMESTEP_END             # ★ 建议显式写上
  [../]
  [./sig_h_aux]
    type = RankTwoScalarAux
    variable = sigma_h
    rank_two_tensor = stress
    scalar_type = Hydrostatic
    #base_name = uncracked
    execute_on = TIMESTEP_END
  [../]
  [./chi_aux]
    type = ParsedAux
    variable = chi
    coupled_variables = 'd'        # <-- tell the parser about 'd'
    expression = 'if(d>0.95, 1, 0)'
    execute_on = TIMESTEP_END
  [../]
  [./C_to_ppm]
    type = ParsedAux
    variable = C_ppm
    coupled_variables = 'C'
    constant_names       = 'rho_M M_H'
    constant_expressions = '${rho_M} ${M_H}'
    expression = '1e6 * C * M_H / rho_M'
    execute_on = 'timestep_end'   
  [../]
  [./chi_node_aux]
    type = ParsedAux
    variable = chi_node
    coupled_variables = 'd'
    constant_names = 'dthr'
    constant_expressions = '0.95'
    expression = 'if(d > dthr, 1, 0)'
    execute_on = TIMESTEP_END
  [../]
  [./r_d095_aux]
    type = ParsedAux
    variable = r_d095
    coupled_variables = 'chi_node'
    use_xyzt = true
    expression = 'sqrt(pow(x, 2) + pow(y, 2)) * chi_node'
    execute_on = TIMESTEP_END
  [../]
[]

[Functions]
  [./current_cycle]
    type = ParsedFunction
    expression = 't * ${cycles_per_step}' ###'t / ${period}' 
  [../]
[]

[BCs] # 2: top,   3:bottom
  [top_cycle]
    type = FunctionDirichletBC
    variable = 'disp_y'
    boundary = 'TOP'
    ## Instead of using cosine function for top displacement, fix it as constant
    ## The energy accumulation is taken by [./current_cycle] block in [Functions]
    #function = '${umax} * 0.5 * (cos(2 * 3.1415926 * t / ${period}) + 1)'
    function = '${umax}'
  []
  [yfix]
    type = DirichletBC
    variable = 'disp_y'
    boundary = "BOTTOM"
    value = 0
  []
  [xfix]
    type = DirichletBC
    variable = 'disp_x'
    boundary = "BOTTOM"
    value = 0
  []
[]


[Materials]
  [./pfbulkmat]
    type = GenericConstantMaterial
    prop_names =  'gc     l     '
    prop_values = '${gc}  ${l}  ' #Gc:MPa mm
  [../]
  [./elasticity_tensor]
    type = ComputeIsotropicElasticityTensor #Constitutive law here
    poissons_ratio = ${nu}
    youngs_modulus = ${E} #MPa
    base_name = uncracked
  [../]
  [./trial_stress]
    type = ComputeFiniteStrainElasticStress
    base_name = uncracked
  [../]
  [./degradation] # Define w(d)
    type = DerivativeParsedMaterial
    property_name = degradation
    coupled_variables = 'd'
    expression = '(1-d)^p*(1-k)+k'
    constant_names       = 'p k'
    constant_expressions = '2 1e-6'
    derivative_order = 2
  [../]
  [./cracked_stress]
    type = ComputePFFStress
    c = d
    E_name = E_el
    D_name = degradation
    decomposition = spectral
    use_current_history_variable = true
    uncracked_base_name = uncracked
    finite_strain_model = true
  [../]
[]

[Postprocessors]
  [./cycle_current]
    type = ElementAverageValue
    variable = n_cycle
  [../]
  [./max_current]
    type = ElementExtremeValue
    variable = current_fatigue
  [../]
  [./max_accumulate]
    type = ElementExtremeValue
    variable = bar_alpha
  [../]
  [./top_stress_yy]
    type = SideAverageValue
    variable = stress_yy
    boundary = 2
  [../]
  [./av_disp_y]
    type = SideAverageValue
    variable = disp_y
    boundary = 2
  [../]
  [./crack_area]
    type = ElementIntegralVariablePostprocessor
    variable = d
  [../]
  [./max_d]
    type = NodalExtremeValue
    variable = d
  [../]
  #[./dt]
  #  type = TimestepSize
  #[../]
  #[./z_n_nl_its]
  #  type = NumNonlinearIterations
  #  accumulate_over_step = true
  #[../]
  #[./z_n_picard_its]
  #  type = NumFixedPointIterations
  #[../]
  [./run_time]
    type = PerfGraphData
    data_type = TOTAL
    section_name = Root
  [../]
      [./length_band]
    type = ElementIntegralVariablePostprocessor
    variable = chi
  #  block = narrow_band_subdomain   # <- set this to your band
  [../]
  [./C]
    type = NodalExtremeValue
    variable = C
  [../]
  #[./C_ppm]
  #  type = ParsedPostprocessor
  #  pp_names = 'C_ppm'
  #  constant_names          = 'rho_M M_H'
  #  constant_expressions    = '${rho_M} ${M_H}'
  #  coupled_variables       = 'C'
  #  expression = '(C*1e6) / rho_M * M_H'
  #[../]
  [./crack_length]
    type = NodalExtremeValue
    variable = r_d095       # 取 max 即为从原点到 d>0.95 最远节点的距离
    execute_on = TIMESTEP_END
  [../]
[]


[Preconditioning]
  [./smp]
    type = SMP
    full = true
 [../]
[]


[Executioner]
  type = Transient

  solve_type = NEWTON #PJFNK  #NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package '
  petsc_options_value = 'lu       superlu_dist                  '
  #solve_type = PJFNK
  #petsc_options_iname = '-pc_type'
  #petsc_options_value = 'lu'
  automatic_scaling = true

  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-7

  #[./TimeStepper]
  #  type = IterationAdaptiveDT
  #  dt = ${deltat} #1e-2
  #  optimal_iterations = 12
  #  cutback_factor = 0.3 
  #  growth_factor = 1.25
  #[../]
  #[./TimeStepper]
  #  type = IterationAdaptiveDT
  #  dt = 0.01
  #  optimal_iterations = 8
  #  cutback_factor = 0.25
  #  growth_factor = 2 #1.5 #1.25
  #  iteration_window   = 2
  #[../]
  dt = ${deltat}
  end_time = ${end_time}
  #num_steps=1
  fixed_point_max_its = 12
  nl_max_its = 40  
  l_max_its = 20  
  accept_on_max_fixed_point_iteration = true
  fixed_point_rel_tol = 1e-6
  fixed_point_abs_tol = 1e-7
[]

[Outputs]
  file_base= Aniso_30_45_SENT13
  exodus = true
  #perf_graph = true
  csv = true
  time_step_interval = 1
[]