E = 21e4 #MPa= 210 GPa
nu = 0.3     #
#gc = 33     #KJ/m2 = MPa.mm
l = 0.2 #0.05    #mm
gc_base  = 33    # 母材 base
gc_weld1 = 25    # 焊缝1
gc_weld2 = 25    # 焊缝2
#gc_HAZ1  = 28    # HAZ1
#gc_HAZ2  = 28    # HAZ2
#gc_pad   = 1e6   # 左右端部用一个超大的 Gc，当成不会断的夹持区
# ===== Frequency-driven timing (seconds) =====



#f           = 1                    # Frequency [Hz]
f           = 1                     # Frequency [Hz]
#period      = ${fparse 1.0 / f}     # Period [s] -> 1.0 s
#num_cycle   = 60000
#end_time    = ${fparse period * num_cycle}   # -> 600000 s
#deltat     = ${fparse 100 * period}



period      = ${fparse 1/f}        # Physical time per cycle [s]
num_cycle   = 3800000               # Number of cycle
cycles_per_step = 100               # How many cycles to advance per step
end_time    = ${fparse num_cycle * period/cycles_per_step} 
deltat      = 1 #${fparse cycles_per_step * period}   # Time step length (s)

# ====== CT load F_top2_Hole cricle ======
#F_top2     = 300 #589.19      # 441.90        # N, Max-load
#r_top2     = 6.25          # mm, Radius
##cy_top2    = 15.0          # mm, y coordinate of the center of the upper hole
#thickness  = 1.0           # mm, 2D Unit thickness
#p_top2     = ${fparse 1*F_top2/(3.14*r_top2*thickness)}   # MPa = N/mm^2 
p_top2     = 10

#=========Hydrogen=============#
#N·mm=10^3 J
M_H        = 0.001008       # kg/mol Molar mass of hydrogen
rho_M      = 7.85e-6        # kg/mm^3 Steel density 


[GlobalParams]
  displacements = 'disp_x disp_y'
[]
[MultiApps]
  # 0) pseudo hydrogen for diffuse HAZ
  [./haz_marker]
    type       = FullSolveMultiApp
    input_files = 'fatigue_H_eta.i'
    execute_on  = INITIAL
  [../]
  # 1) 24h pre-charge hydrogen
  # 24*3600 =  86400 s
  [./hyd_precharge] #Pre-charge hydrogen: When starting, first diffuse hydrogen for 24 hours
    type = FullSolveMultiApp
    input_files = 'fatigue_H_C_pre.i'
    execute_on = INITIAL
    #max_procs_per_app = 1
  [../]
  # 2) transient hydrogen during fatigue
  [./hyd]
    type = TransientMultiApp
    input_files = 'fatigue_H_C.i'     # Hydrogen
    execute_on = TIMESTEP_END
  [../]
  # 3) phase-field crack
  [./crack]
    type = TransientMultiApp
    input_files = 'fatigue_H_f.i'     # PF
    execute_on = TIMESTEP_END
  [../]
[]

[Transfers]
#====================== haz_marker (eta_HAZ) ======================
  [./from_haz_marker_to_main]
    type           = MultiAppProjectionTransfer
    from_multi_app = haz_marker
    source_variable = eta_HAZ     # 子应用中的变量名
    variable        = eta_HAZ     # 主程序 AuxVariable
    execute_on      = INITIAL
  [../]
    # eta_HAZ main -> crack (只需要初始一次即可)
  [./to_crack_eta_HAZ]
    type           = MultiAppProjectionTransfer
    to_multi_app   = crack
    source_variable = eta_HAZ
    variable        = eta_HAZ
    execute_on      = 'INITIAL TIMESTEP_BEGIN'
  [../]
  ########## Main -> hyd ##########
  [./to_hyd_eta_HAZ]
    type            = MultiAppProjectionTransfer
    to_multi_app    = hyd
    source_variable = eta_HAZ
    variable        = eta_HAZ
    execute_on      = 'INITIAL TIMESTEP_BEGIN'
  [../]
  # from crack app → main: gc_field
[./from_crack_gc_to_main]
  type           = MultiAppProjectionTransfer
  from_multi_app = crack
  source_variable = gc_field    # crack 应用里的变量名
  variable        = gc_field    # main 里的 AuxVariable
  execute_on      = TIMESTEP_END
[../]
#====================== haz_marker (eta_HAZ) ======================

#====================== 24 h hyd_precharge ======================
# 1 hyd_precharge  ->  Main
  [./from_hyd_precharge_C_to_main]
    type = MultiAppProjectionTransfer
    from_multi_app  = hyd_precharge
    source_variable = C
    variable        = C        # 主程序里的 AuxVariable C
    execute_on      = INITIAL
  [../]

# 2 Main  ->  crack
  [./to_crack_C_initial]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    to_multi_app     = crack
    source_variable  = C
    variable         = C
    execute_on       = 'INITIAL TIMESTEP_BEGIN'
  [../]

# 3 Main  ->  hyd
  [./to_hyd_C_initial]
    type = MultiAppProjectionTransfer
    to_multi_app     = hyd
    source_variable  = C
    variable         = C
    execute_on       = 'INITIAL TIMESTEP_BEGIN'
  [../]
#====================== 24 h hyd_precharge ======================

########## PF -> Main ##########
  [./from_crack_d]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'd'
    variable = 'd'
    execute_on = TIMESTEP_END
  [../]

  [./from_current_fatigue]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'current_fatigue'
    variable = 'current_fatigue'
    execute_on = TIMESTEP_END
  [../]

  [./from_accumulate_fatigue]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'bar_alpha'
    variable = 'bar_alpha'
    execute_on = TIMESTEP_END
  [../]

  [./from_fatigue_function]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    from_multi_app = 'crack'
    source_variable = 'f_alpha'
    variable = 'f_alpha'
    execute_on = TIMESTEP_END
  [../]

  [./from_kappa]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
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
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    from_multi_app = hyd
    source_variable = C
    variable = C
    execute_on = TIMESTEP_END
  [../]

########## Main -> PF ##########
  [./to_crack_disp_x]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    to_multi_app = 'crack'
    source_variable = 'disp_x'
    variable = 'disp_x'
    execute_on = TIMESTEP_BEGIN
  [../]
  [./to_crack_disp_y]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    to_multi_app = 'crack'
    source_variable = 'disp_y'
    variable = 'disp_y'
    execute_on = TIMESTEP_BEGIN
  [../]
  [./to_crack_CLA]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    to_multi_app = 'crack'
    source_variable = 'n_cycle'
    variable = 'n_cycle'
    execute_on = TIMESTEP_BEGIN
  [../]

  
  [./to_crack_C]
    type = MultiAppProjectionTransfer   #MultiAppCopyTransfer
    to_multi_app = crack
    source_variable = C
    variable = C
    execute_on = TIMESTEP_BEGIN      # 用上一步的 C，避免强耦合
  [../]
[]


[Mesh]
  file = weld5.inp
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
    # pseudo marker for diffuse HAZ (from haz_marker app)
  [./eta_HAZ]
    family = LAGRANGE
    order  = FIRST
  [../]
  [./gc_field]
    family = MONOMIAL
    order  = FIRST
  [../]

# ---------- Hydrogen ---------- 
# ---------- Crack_length ---------- 
  [./r_mask]  family = LAGRANGE  order = FIRST  []
  [./x_mask]
    family = LAGRANGE
    order  = FIRST
  [../]
# ---------- Crack_length ---------- 
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
  # ---------- Crack_length ---------- 
  [./r_mask_aux]
    type = ParsedAux
    variable = r_mask
    coupled_variables = 'd'
    use_xyzt = true
    constant_names       = 'x0 y0 dthr'
    constant_expressions = '-9.125 0 0.95'   # ← 原点=初始尖端(x0,y0)，阈值可改0.9做对比
    expression = 'if(d > dthr, sqrt(pow(x - x0, 2) + pow(y - y0, 2)), -1e12)'
    execute_on = TIMESTEP_END
  [../]
  [./x_mask_aux]
    type = ParsedAux
    variable = x_mask
    coupled_variables = 'd'
    use_xyzt = true
    expression = 'if(d > 0.95, x, -1e12)'
    execute_on = TIMESTEP_END
  [../]
  # ---------- Crack_length ---------- 
[]

[Functions]
  [./current_cycle]
    type = ParsedFunction
    expression = 't * ${cycles_per_step}' ###'t / ${period}' 
  [../]
[]


#[Functions]
#  [./current_cycle]
#    type = ParsedFunction
#    expression = 't / ${period}'
#  [../]
#[]

[BCs] # Set-9=half Upper circle #bottom2 = whole bottom circle
  #[./top2_pressure_x]
  #  type       = ADPressure
  #  boundary   = 'top2'
  #  variable   = disp_x
  #  component  = 0
  #  function   = '${p_top2}'
  #[../]
  [./top2_pressure_y]
    type       = ADPressure
    boundary   = 'internal'
    variable   = disp_y
  # component  = 1
    function   = '${p_top2}'
  [../]
  [./fix_bottom2_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'right'
    value = 0
  [../]
    [./fix_bottom2_y1]
    type = DirichletBC
    variable = disp_y
    boundary = 'left'
    value = 0
  [../]
  [./fix_bottom2_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  [../]
    [./fix_bottom2_x1]
    type = DirichletBC
    variable = disp_x
    boundary = 'right'
    value = 0
  [../]
[]


[Materials]
  [./pfbulkmat]
    type = GenericConstantMaterial
    prop_names =  'l     '
    prop_values = '${l}  ' #Gc:MPa mm
  [../]
  [./gc_base]
    type = GenericConstantMaterial
    block = 'base_TRI3 base_QUAD4 left_QUAD4 right_QUAD4'
    prop_names  = 'gc'
    prop_values = '${gc_base}'
  [../]

  # 2) 焊缝1
  [./gc_weld1]
    type = GenericConstantMaterial
    block = 'weld1_QUAD4'
    prop_names  = 'gc'
    prop_values = '${gc_weld1}'
  [../]

  # 3) 焊缝2
  [./gc_weld2]
    type = GenericConstantMaterial
    block = 'weld2_QUAD4'
    prop_names  = 'gc'
    prop_values = '${gc_weld2}'
  [../]

  # 4) HAZ1: diffuse gc using eta_HAZ (0 at WM side, 1 at BM side)
  [./gc_HAZ1_diffuse]
    type          = ParsedMaterial
    block         = 'HAZ1_QUAD4 line1_QUAD4  line1-1_QUAD4'
    property_name = 'gc'

    # gc = gc_weld1 + eta_HAZ * (gc_base - gc_weld1)
    expression = 'gcw1 + eta_HAZ * (gcb - gcw1)'

    constant_names        = 'gcw1 gcb'
    constant_expressions  = '${gc_weld1} ${gc_base}'
    coupled_variables     = 'eta_HAZ'
  [../]

  # 5) HAZ2: same idea, but starting from gc_weld2
  [./gc_HAZ2_diffuse]
    type          = ParsedMaterial
    block         = 'HAZ2_QUAD4 line2_QUAD4  line2-2_QUAD4 internal_QUAD4'
    property_name = 'gc'

    expression = 'gcw2 + eta_HAZ * (gcb - gcw2)'

    constant_names        = 'gcw2 gcb'
    constant_expressions  = '${gc_weld2} ${gc_base}'
    coupled_variables     = 'eta_HAZ'
  [../]

  #[./gc_pad]
  #  type = GenericConstantMaterial
  #  block = 'internal_QUAD4 left_QUAD4 right_QUAD4'
  #  prop_names  = 'gc'
  #  prop_values = '${gc_pad}'
  #[../]

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
  [./C_min_initial]
    type = NodalExtremeValue
    variable = C
    value_type = MIN
    execute_on = INITIAL
  [../]
  [./C_max_initial]
    type = NodalExtremeValue
    variable = C
    value_type = MAX
    execute_on = INITIAL
  [../]
  #======================  ======================
    [./length_band]
    type = ElementIntegralVariablePostprocessor
    variable = chi
  #  block = narrow_band_subdomain   # <- set this to your band
  [../]
  
  [./C]
    type = NodalExtremeValue
    variable = C
  [../]
  # ---------- Crack_length ---------- 
  [./crack_length_r]
    type       = NodalExtremeValue
    variable   = r_mask
    value_type = MAX
    execute_on = TIMESTEP_END
  [../]
  [./x_tip0]
    type  = ConstantPostprocessor
    value = -2.25         # 你的初始尖端 x0
  [../]

  [./xmax_d095]
    type       = NodalExtremeValue
    variable   = x_mask   # ← 这里换成 x_mask
    value_type = MAX
    execute_on = TIMESTEP_END
  [../]

  [./crack_length_x]
    type       = ParsedPostprocessor
    pp_names   = 'xmax_d095 x_tip0'
    expression = 'xmax_d095 - x_tip0'   # 若向 -x 走，用 x_tip0 - xmax_d095
    execute_on = TIMESTEP_END
  [../]
  # ---------- Crack_length ---------- 
[]






[Preconditioning]
  [./smp]
    type = SMP
    full = true
 [../]
[]

[Adaptivity]
  marker = combo
  initial_marker = init_refine
  max_h_level = 2                 # 0.2 / 2^6 = 0.003125 < ℓ/3 ≈ 0.00533
  cycles_per_step = 5
  recompute_markers_during_cycles = true

  [./Indicators]
    [./jump]
      type = GradientJumpIndicator
      variable = d
    [../]
  [../]


  [./Markers]
    [./band]
      type = ValueRangeMarker
      variable = d
      lower_bound = 0.1
      upper_bound = 0.99
      buffer_size = 0.02
      third_state = DO_NOTHING
    [../]

    [./err]
      type = ErrorFractionMarker
      indicator = jump
      refine  = 0.3              # 只跟随最陡的 8% 区域
      coarsen = 0
    [../]

   [./combo]
     type = ComboMarker
    markers = 'band err'
#     markers = 'err'
   [../]
   [../]
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package '
  petsc_options_value = 'lu       superlu_dist                  '
  #solve_type = PJFNK
  #petsc_options_iname = '-pc_type'
  #petsc_options_value = 'lu'
  automatic_scaling = true

  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-7

#  [./TimeStepper]
#    type = IterationAdaptiveDT
#    dt = 0.5
#    optimal_iterations = 15
#    cutback_factor = 0.05 
#    growth_factor = 1.3
#  [../]
  dt = ${deltat}
  end_time = ${end_time}
  #num_steps=1
  fixed_point_max_its = 12
  nl_max_its = 100
  l_max_its = 30  
  accept_on_max_fixed_point_iteration = true
  fixed_point_rel_tol = 1e-6
  fixed_point_abs_tol = 1e-7

#  [Adaptivity]
#  [./Markers]
 #   [./marker]
 #     type = ValueThresholdMarker
 #     coarsen = 0.3
 #     variable = d
  #    refine = 0.7
  #  [../]
  #  [./inverted_marker]
  #    type = ValueThresholdMarker
  #    invert = true
   #   coarsen = 0.7
  #    refine = 0.3
   #   variable = d
   #   third_state = DO_NOTHING
  #  [../]
 # [../]
#[]

[]

[Outputs]
  file_base=Fatigue_Hydrogen_CT_4
  exodus = true
  #perf_graph = true
  csv = true
  time_step_interval = 1
[]