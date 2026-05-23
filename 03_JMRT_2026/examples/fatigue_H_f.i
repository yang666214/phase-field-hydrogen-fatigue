########Equilibrium System parameters############
E = 21.0e4 #MPa
nu = 0.3
########Equilibrium System parameters############


########PFF system############
# 不同区域的临界断裂能（示意数值，自行修改）
gc_base  = 33    # 母材 base
gc_weld1 = 50    # 焊缝1
gc_weld2 = 50    # 焊缝2
#gc_HAZ1  = 28    # HAZ1
#gc_HAZ2  = 28    # HAZ2
#gc_pad   = 1e6   # 左右端部用一个超大的 Gc，当成不会断的夹持区

l  = 0.2
xi = 0
C0 = 2
L  = 1e4
########PFF system############


########Fatigue############
#alpha_critical0 = 80   #41.6 #30 #MPa Gc
alpha_crit_base  = 60   # 母材 threshold（大）
alpha_crit_weld1 = 15   # 焊缝1 threshold（小）
alpha_crit_weld2 = 15   # 焊缝2 threshold（小）
R=0.5  #0.5
#n=2.75 #0.5
n_base  = 2.85   # 母材
n_weld1 = 2.95    # 焊缝1
n_weld2 = 2.95    # 焊缝2

########Fatigue############

########Hydrogen (cui)############
#N·mm=10^3 J
#M_H        = 0.001008       # kg/mol Molar mass of hydrogen
#rho_M      = 7.85e-6        # kg/mm^3 Steel density 

########Hydrogen############

########Hydrogen (new)############
#N·mm=10^3 J
M_H        = 0.001008       # kg/mol Molar mass of hydrogen
rho_M      = 7.85e-6        # kg/mm^3 Steel density 

########Hydrogen############

########Hydrogen (Emilio) ############
#N·mm=10^3 J
#rho_M      = 7.85e-6        # kg/mm^3 Steel density 
#chi        = 0.89           # hydrogen damage coefficient
#Delta_g0b  = 3.0e4#3.0e4          # J/mol, binding energy Δg0b≈30 kJ/mol
#R_gas      = 8.314          # J/(mol·K) gas constant
#A_M        = 55.845e-3      # kg/mol atomic weight of steel
#T0         = 300            # K
########Hydrogen############

[Mesh]
  file = weld5.inp
  uniform_refine = 0
  skip_partitioning = true
  construct_side_list_from_node_list=true
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Actions/PFNonconserved]
  [./d]
    free_energy = F
    kappa = kappa_op
    mobility = L
    variable_mobility=false
    use_automatic_differentiation = true
    use_anisotropic_matrix =false # true
    #anisotropic_matrix = A_matrix
  [../]
[]

[Variables]
  [./d]
    family = LAGRANGE
    order  = FIRST
  [../]
[]

[AuxVariables]
  [./bounds_dummy]
  [../]
  #[./disp_x]
  #[../]
  #[./disp_y]
  #[../]
  [./disp_x]
    family = LAGRANGE
    order  = FIRST
  [../]
  [./disp_y]
    family = LAGRANGE
    order  = FIRST
  [../]
  # diffuse HAZ marker from haz_marker app
  [./eta_HAZ]
    family = LAGRANGE
    order  = FIRST
  [../]
# ---- NEW: output field for fracture toughness gc ----
  [./gc_field]
    family = MONOMIAL   # 每个单元一个值就够了
    order  = FIRST
  [../]
  [./alphaT_field]
    family = MONOMIAL   # 每个单元一个值就够了
    order  = FIRST
  [../]
  [./n_field]
    family = MONOMIAL   # 每个单元一个值就够了
    order  = FIRST
  [../]

  ### Fatigue Related ###
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
    ### Hydrogen Related ###
  [./C]                      # Hydrogen concentration
    family = LAGRANGE
    order  = FIRST    # mol/mm^3
  [../]

[]

# ---------- Initial condition ----------
#[ICs]
#  [./d_ic]
#    type = FunctionIC
#    function = ic
#    variable = d
#  [../]
#[]

#[Functions]
#  [./ic]
#    type = ParsedFunction
#    expression = 'if( (x>-6 & x<8.5) & (y>350 & y<351), 1, 0 )'
#  [../]
#[]

[ICs]
  [./d_ic]
    type = FunctionIC
    variable = d
    function = ic
    block = 'weld1_QUAD4 weld2_QUAD4 HAZ1_QUAD4 HAZ2_QUAD4'  # 这里限制只在焊缝里施加初始缺陷
  [../]
[]

[Functions]
  [./ic]
    type = ParsedFunction
    expression = '1*exp(-((x-10)^2 + (y-344)^2)/(0.5^2)) + 1*exp(-((x-15)^2 + (y-344)^2)/(0.5^2)) + 1*exp(-((x-10)^2 + (y-350)^2)/(0.5^2))'
  [../]
[]


# ---------- Initial condition ----------

[AuxKernels]
  [./current_fatigue]
    type = ADMaterialRealAux
    variable = current_fatigue
    property = current_fatigue
  [../]
  [./bar_alpha]
    type = ADMaterialRealAux
    variable = bar_alpha
    property = bar_alpha
    execute_on = timestep_end
  [../]
  [./f_alpha]
    type = ADMaterialRealAux
    variable = f_alpha
    property = f_alpha
  [../]
  [./kappa_op]
    type = ADMaterialRealAux
    variable = kappa_op
    property = kappa_op
  [../]
  # ---- NEW: map material property 'gc' to aux variable 'gc_field' ----
  [./gc_field_aux]
    type     = ADMaterialRealAux
    variable = gc_field
    property = gc           # 就是你在 Materials 里用的 property_name
    execute_on = 'INITIAL TIMESTEP_END'
  [../]
    # ---- NEW: map material property 'alphaT' to aux variable 'alphaT_field' ----
  [./alphaT_field_aux]
    type     = ADMaterialRealAux
    variable = alphaT_field
    property = alpha_critical           # 就是你在 Materials 里用的 property_name
    execute_on = 'INITIAL TIMESTEP_END'
  [../]
    # ---- NEW: map material property 'n' to aux variable 'n_field' ----
  [./n_field_aux]
    type     = ADMaterialRealAux
    variable = n_field
    property = material_constant_n           # 就是你在 Materials 里用的 property_name
    execute_on = 'INITIAL TIMESTEP_END'
  [../]
[]

[Materials]
  #[./anisotropy]
  #  type = ADAnisotropicDirector
  #  normal = "0 1 0"
  #  coef = 100
  #  normalize_director = trace_norm #factorial_norm #det_norm #none
  #  output_name = A_matrix
  #[]
  [elasticity]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = ${E}
    poissons_ratio = ${nu}
    base_name = uncracked
  []
  [./uncracked_strain]
    type = ADComputeFiniteStrain
    base_name = uncracked
  [../]

  [./trial_stress]
    type = ADComputeFiniteStrainElasticStress
    base_name = uncracked
  [../]
#####################Start : Hydrogen dragation function (Cui) ###########################
  # 1) Direct calculation hydrogen: from C mol/mm^3 to wt ppm
 # [./c_from_mol_mm] 
 #   type = ADParsedMaterial
 #   property_name = 'C_ppm'
 #   expression = '(C*1e6) / rho_M * M_H'
 #   coupled_variables       = 'C'
 #   constant_names          = 'rho_M M_H'
 #   constant_expressions    = '${rho_M} ${M_H}'
 #   #outputs = exodus
 # [../]

  # 2) fC = 0.12+(1-0.12)*exp(-7*C_ppm^2)
 # [./hydrogen_fC]
 #   type = ADParsedMaterial
 #   property_name = 'fC'
 #   expression = '0.12+(1-0.12)*exp(-7*C_ppm^2)'
 #   material_property_names = 'C_ppm'
 #   #outputs = exodus
 # [../]

#####################Start : Hydrogen dragation function (new) ###########################
  # 1) Direct calculation hydrogen: from C mol/mm^3 to wt ppm
  [./c_from_mol_mm] 
    type = ADParsedMaterial
    property_name = 'C_ppm'
    expression = '(C*1e6) / rho_M * M_H'
    coupled_variables       = 'C'
    constant_names          = 'rho_M M_H'
    constant_expressions    = '${rho_M} ${M_H}'
    #outputs = exodus
  [../]

  # 2) fC = 0.155+(1-0.155)*exp(-24.1*C_ppm^2)
  [./hydrogen_fC]
    type = ADParsedMaterial
    property_name = 'fC'
    expression = '0.155+(1-0.155)*exp(-24.1*C_ppm^2)'
    material_property_names = 'C_ppm'
    #outputs = exodus
  [../]  

#####################Start : Hydrogen dragation function (Emilio) ###########################
  # 1) Direct calculation of c from wt ppm
  # Dimension: Ratio of hydrogen atoms per metal atom
  #[./c_from_wppm]
  #  type = ADParsedMaterial
  #  property_name = 'c_imp'
  #  # c = C * A_M / rho_M   (C: mol/mm^3, A_M: kg/mol, rho_M: kg/mm^3) → dimensionless
  #  expression = 'C * A_M / rho_M'
  #  coupled_variables       = 'C'
  #  constant_names          = 'A_M rho_M'
  #  constant_expressions    = '${A_M} ${rho_M}'
  #  #outputs = exodus
  #[../]

  # 2) θ_s = c/(c + exp(-Δg_b0/(R*T0)))；
  #[./theta_surface]
  #  type = ADParsedMaterial
  #  property_name = 'theta_s'
  #  expression = 'c_imp / (c_imp + exp(-Delta_g0b/(R_gas*T0)))'
  #  material_property_names = 'c_imp'
  #  constant_names          = 'Delta_g0b R_gas T0'
  #  constant_expressions    = '${Delta_g0b} ${R_gas} ${T0}'
  #  #outputs = exodus
  #[../]

  # 3) fC = 1 - chi * theta_s
  #[./hydrogen_fC]
  #  type = ADParsedMaterial
  #  property_name = 'fC'
  #  expression = '1.0 - chi*theta_s'
  #  material_property_names = 'theta_s'
  #  constant_names          = 'chi'
  #  constant_expressions    = '${chi}'
  #  #outputs = exodus
  #[../]
#####################End : Hydrogen dragation function ###########################


  [./public_materials_forPF_model]
    type = ADGenericConstantMaterial
    prop_names  = 'l xi C0 L'
    prop_values = '${l} ${xi} ${C0} ${L}'
  [../]
  #===============start====gc===============
  [./gc_base]
    type = ADGenericConstantMaterial
    block = 'base_TRI3 base_QUAD4 left_QUAD4 right_QUAD4'
    prop_names  = 'gc'
    prop_values = '${gc_base}'
  [../]

  # 2) 焊缝1
  [./gc_weld1]
    type = ADGenericConstantMaterial
    block = 'weld1_QUAD4'
    prop_names  = 'gc'
    prop_values = '${gc_weld1}'
  [../]

  # 3) 焊缝2
  [./gc_weld2]
    type = ADGenericConstantMaterial
    block = 'weld2_QUAD4'
    prop_names  = 'gc'
    prop_values = '${gc_weld2}'
  [../]

  # 4) HAZ1: diffuse gc using eta_HAZ (0 at WM side, 1 at BM side)
  [./gc_HAZ1_diffuse]
    type          = ADParsedMaterial
    block         = 'HAZ1_QUAD4 line1_QUAD4  line1-1_QUAD4'
    property_name = 'gc'

    # gc = gc_weld1 + eta_HAZ * (gc_base - gc_weld1)
    expression = 'gcw1 + eta_HAZ * (gcb - gcw1)'
    #expression = 'eta_HAZ*10000000'
    constant_names        = 'gcw1 gcb'
    constant_expressions  = '${gc_weld1} ${gc_base}'
    coupled_variables     = 'eta_HAZ'
  [../]

  # 5) HAZ2: same idea, but starting from gc_weld2
  [./gc_HAZ2_diffuse]
    type          = ADParsedMaterial
    block         = 'HAZ2_QUAD4 line2_QUAD4  line2-2_QUAD4 internal_QUAD4'
    property_name = 'gc'

    expression = 'gcw2 + eta_HAZ * (gcb - gcw2)'
    #expression = 'eta_HAZ*10000000'
    constant_names        = 'gcw2 gcb'
    constant_expressions  = '${gc_weld2} ${gc_base}'
    coupled_variables     = 'eta_HAZ'
  [../]
#===============end====gc===============
  [./fatigue_R]
    type       = ADGenericConstantMaterial
    prop_names = 'load_ratio'
    prop_values= '${R}'
  [../]
#===============start====material_constant_n===============
  # --- n：母材 ---
  [./n_base]
    type       = ADGenericConstantMaterial
    block      = 'base_TRI3 base_QUAD4 left_QUAD4 right_QUAD4'
    prop_names = 'material_constant_n'
    prop_values= '${n_base}'
  [../]

  # --- n：焊缝1 ---
  [./n_weld1]
    type       = ADGenericConstantMaterial
    block      = 'weld1_QUAD4'
    prop_names = 'material_constant_n'
    prop_values= '${n_weld1}'
  [../]

  # --- n：焊缝2 ---
  [./n_weld2]
    type       = ADGenericConstantMaterial
    block      = 'weld2_QUAD4'
    prop_names = 'material_constant_n'
    prop_values= '${n_weld2}'
  [../]

  # --- n：HAZ1 渐变 ---
  [./n_HAZ1_diffuse]
    type          = ADParsedMaterial
    block         = 'HAZ1_QUAD4 line1_QUAD4  line1-1_QUAD4'
    property_name = 'material_constant_n'

    # n = n_weld1 + eta_HAZ*(n_base - n_weld1)
    expression          = 'nw1 + eta_HAZ*(nb - nw1)'
    constant_names       = 'nw1 nb'
    constant_expressions = '${n_weld1} ${n_base}'
    coupled_variables    = 'eta_HAZ'
  [../]

  # --- n：HAZ2 渐变 ---
  [./n_HAZ2_diffuse]
    type          = ADParsedMaterial
    block         = 'HAZ2_QUAD4 line2_QUAD4  line2-2_QUAD4 internal_QUAD4'
    property_name = 'material_constant_n'
    expression          = 'nw2 + eta_HAZ*(nb - nw2)'
    constant_names       = 'nw2 nb'
    constant_expressions = '${n_weld2} ${n_base}'
    coupled_variables    = 'eta_HAZ'
  [../]

#===============end====material_constant_n===============
  [./fatigue_variable]
    type = ADComputeFatigueEnergy
    #energy_calculation = mean_load
    uncracked_base_name = uncracked
    finite_strain_model = true
    multiply_by_D = false
    accumulation_mode = FatigueICLA
    N_cyc_variable = n_cycle
    acc_bar_psi_name = bar_alpha
    bar_psi_name = current_fatigue
    [../]
#===============start====alpha_critical_const===============
    # --- alpha_critical：母材常数 ---
  [./alpha_critical_base]
    type       = ADGenericConstantMaterial
    block      = 'base_TRI3 base_QUAD4 left_QUAD4 right_QUAD4'
    prop_names = 'alpha_critical'
    prop_values= '${alpha_crit_base}'
  [../]

  # --- alpha_critical：焊缝1 常数 ---
  [./alpha_critical_weld1]
    type       = ADGenericConstantMaterial
    block      = 'weld1_QUAD4'
    prop_names = 'alpha_critical'
    prop_values= '${alpha_crit_weld1}'
  [../]

  # --- alpha_critical：焊缝2 常数 ---
  [./alpha_critical_weld2]
    type       = ADGenericConstantMaterial
    block      = 'weld2_QUAD4'
    prop_names = 'alpha_critical'
    prop_values= '${alpha_crit_weld2}'
  [../]

  # --- alpha_critical：HAZ1 渐变 ---
  [./alpha_critical_HAZ1_diffuse]
    type          = ADParsedMaterial
    block         = 'HAZ1_QUAD4 line1_QUAD4  line1-1_QUAD4'
    property_name = 'alpha_critical'

    # alpha = alpha_weld1 + eta_HAZ * (alpha_base - alpha_weld1)
    expression          = 'ac_w1 + eta_HAZ * (ac_b - ac_w1)'
    constant_names       = 'ac_w1 ac_b'
    constant_expressions = '${alpha_crit_weld1} ${alpha_crit_base}'
    coupled_variables    = 'eta_HAZ'
  [../]

  # --- alpha_critical：HAZ2 渐变 ---
  [./alpha_critical_HAZ2_diffuse]
    type          = ADParsedMaterial
    block         = 'HAZ2_QUAD4 line2_QUAD4  line2-2_QUAD4 internal_QUAD4'
    property_name = 'alpha_critical'

    expression          = 'ac_w2 + eta_HAZ * (ac_b - ac_w2)'
    constant_names       = 'ac_w2 ac_b'
    constant_expressions = '${alpha_crit_weld2} ${alpha_crit_base}'
    coupled_variables    = 'eta_HAZ'
  [../]

#============end=======alpha_critical_const===============

  [./fatigue_function]
    type = ADParsedMaterial
    material_property_names = 'bar_alpha alpha_critical'
    property_name = f_alpha
    expression = 'if(bar_alpha > alpha_critical, (2*alpha_critical/(bar_alpha + alpha_critical))^2, 1)'
    #'if(bar_alpha > 0, (alpha_critical/(bar_alpha + alpha_critical))^2, 1)'
    #'if(bar_alpha > alpha_critical, (2*alpha_critical/(bar_alpha + alpha_critical))^2, 1)'
  [] 


  [./degradation] # Define w(d)
    type = ADDerivativeParsedMaterial
    property_name = degradation
    coupled_variables = 'd'
    expression = '(1-d)^p*(1-k)+k'
    constant_names       = 'p k'
    constant_expressions = '2 1e-6'
    derivative_order = 2
  [../]
  [./local_fracture_energy] #Define psi_frac and alpha(d)
    type = ADDerivativeParsedMaterial
    property_name = local_fracture_energy
    coupled_variables = 'd'
    material_property_names = 'gc l xi C0 f_alpha fC'
    expression = '(xi*d+(1-xi)*d^2)* (gc / l)/C0* f_alpha*fC'
    derivative_order = 2
  [../]
  [./define_kappa]
    type = ADParsedMaterial
    material_property_names = 'gc l C0 f_alpha fC'
    property_name = kappa_op
    expression = '2 * gc * l / C0* f_alpha*fC'
  [../]
  [./cracked_stress]
    type = ADComputePFFStress
    decomposition = spectral
    #type = ADPFFRCEStress
    c = d
    E_name = E_el
    D_name = degradation
    use_current_history_variable = true
    uncracked_base_name = uncracked
    finite_strain_model = true
  [../]
  [./fracture_driving_energy]
    type = ADDerivativeSumMaterial
    coupled_variables = d
    sum_materials = 'E_el local_fracture_energy'
    derivative_order = 2
    property_name = F
  [../]

[]


[Bounds]
  [./d_upper_bound]
    type = ConstantBounds
    variable = bounds_dummy
    bounded_variable = d
    bound_type = upper
    bound_value = 1.0
  [../]
  [./d_lower_bound]
    type = VariableOldValueBounds
    variable = bounds_dummy
    bounded_variable = d
    bound_type = lower
  [../]
[]
[BCs]
  [./d_clamp]
    type = DirichletBC
    variable = d
    boundary = 'base'  # 用的是 sideset 名，不是 *_QUAD4
    value = 0
  [../]
[]
#[Postprocessors]
#  [./max_d]
#    type = NodalExtremeValue
#    variable = d
#    value_type = max
#    execute_on = 'TIMESTEP_END'
#  [../]
#[]

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
      refine  = 0.8              # 只跟随最陡的 8% 区域
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
  petsc_options_iname = '-pc_type -snes_type'
  petsc_options_value = 'lu vinewtonrsls'
  automatic_scaling = true
  nl_max_its = 100
  nl_rel_tol = 1e-5
  nl_abs_tol = 1e-6





[]


[Outputs]
  print_linear_residuals = false
  exodus   = true
  file_base = 'HAZ_marker1'
[]