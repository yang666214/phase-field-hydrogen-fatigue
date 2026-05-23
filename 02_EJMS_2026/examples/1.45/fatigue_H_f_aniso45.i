########Equilibrium System parameters############
E = 21.0e4 #MPa
nu = 0.3
########Equilibrium System parameters############


########PFF system############
gc0 = 2.7 #10    #2.7     #KJ/m2 = MPa.mm
l = 0.016    #0.016    #mm
xi = 0
C0 = 2
L = 1e4
########PFF system############

########Fatigue############
alpha_critical0 = 5 #30 #MPa
R=0.5  #0.5
n=0.5 #0.5
########Fatigue############

########Hydrogen############
#N·mm=10^3 J
#M_H        = 0.001008       # kg/mol Molar mass of hydrogen
rho_M      = 7.85e-6        # kg/mm^3 Steel density 
chi        = 0.89           # hydrogen damage coefficient
Delta_g0b  = 3.0e4#3.0e4          # J/mol, binding energy Δg0b≈30 kJ/mol
R_gas      = 8.314          # J/(mol·K) gas constant
A_M        = 55.845e-3      # kg/mol atomic weight of steel
T0         = 300            # K
########Hydrogen############

[Mesh]
  file = SENT13.inp
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
    use_anisotropic_matrix = true
    anisotropic_matrix = A_matrix
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
[]

[Materials]
  [./anisotropy]
    type = ADAnisotropicDirector
    normal = "-0.70710678 0.70710678 0" #"0 1 0"#"-0.70710678 0.70710678 0"
    coef = 20
    normalize_director = none
    output_name = A_matrix
  []
  #[./anisotropy]
  #  type = ADAnisotropicDirector
  #  normal = "1 0 0"#"-0.70710678 0.70710678 0"
  #  coef = 30
  #  normalize_director = factorial_norm
  #  factor = 0.01
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
#####################Start : Hydrogen Coupling Relationship###########################
  # 1) Direct calculation hydrogen: from C mol/mm^3 to wt ppm
  #[./c_from_mol_mm] 
  #  type = ADParsedMaterial
  #  property_name = 'C_ppm'
  #  expression = '(C*1e6) / rho_M * M_H'
  #  coupled_variables       = 'C'
  #  constant_names          = 'rho_M M_H'
  #  constant_expressions    = '${rho_M} ${M_H}'
  #  #outputs = exodus
  #[../]

  # 2) fC = 0.12+(1-0.12)*exp(-7*C_ppm^2)
  #[./hydrogen_fC]
  #  type = ADParsedMaterial
  #  property_name = 'fC'
  #  expression = '0.12+(1-0.12)*exp(-7*C_ppm^2)'
  #  material_property_names = 'C_ppm'
  #  #outputs = exodus
  #[../]

#####################Start : Hydrogen Coupling Relationship###########################
  # 1) Direct calculation of c from wt ppm
  # Dimension: Ratio of hydrogen atoms per metal atom
  [./c_from_wppm]
    type = ADParsedMaterial
    property_name = 'c_imp'
    # c = C * A_M / rho_M   (C: mol/mm^3, A_M: kg/mol, rho_M: kg/mm^3) → dimensionless
    expression = 'C * A_M / rho_M'
    coupled_variables       = 'C'
    constant_names          = 'A_M rho_M'
    constant_expressions    = '${A_M} ${rho_M}'
    #outputs = exodus
  [../]

  # 2) θ_s = c/(c + exp(-Δg_b0/(R*T0)))；
  [./theta_surface]
    type = ADParsedMaterial
    property_name = 'theta_s'
    expression = 'c_imp / (c_imp + exp(-Delta_g0b/(R_gas*T0)))'
    material_property_names = 'c_imp'
    constant_names          = 'Delta_g0b R_gas T0'
    constant_expressions    = '${Delta_g0b} ${R_gas} ${T0}'
    #outputs = exodus
  [../]

  # 3) fC = 1 - chi * theta_s
  [./hydrogen_fC]
    type = ADParsedMaterial
    property_name = 'fC'
    expression = '1.0 - chi*theta_s'
    material_property_names = 'theta_s'
    constant_names          = 'chi'
    constant_expressions    = '${chi}'
    #outputs = exodus
  [../]
#####################Start : Hydrogen Coupling Relationship###########################


  [./public_materials_forPF_model]
    type = ADGenericConstantMaterial
    prop_names =  '  l      xi    C0    gc     L  ' # density k0=(2650 ,   3.1) are not used here, so do not included them
    prop_values = '  ${l}   ${xi} ${C0}   ${gc0}   ${L}' #'0 2'#for AT2 # Or use '1 2.6666667' for AT1
  [../]

  [./fatigue_mats]
    type = ADGenericConstantMaterial
    prop_names =  "load_ratio  material_constant_n   "
    prop_values = "${R}        ${n}                  "
  [../]
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
    []

  [./alpha_critical_const]
  type = ADGenericConstantMaterial
  prop_names  = 'alpha_critical'
  prop_values = '${alpha_critical0}'
  [../]


  [./fatigue_function]
    type = ADParsedMaterial
    material_property_names = 'bar_alpha alpha_critical'
    property_name = f_alpha
    expression = 'if(bar_alpha > alpha_critical, (2*alpha_critical/(bar_alpha + alpha_critical))^2, 1)'
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

#[Postprocessors]
#  [./max_d]
#    type = NodalExtremeValue
#    variable = d
#    value_type = max
#    execute_on = 'TIMESTEP_END'
#  [../]
#[]


[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -snes_type'
  petsc_options_value = 'lu vinewtonrsls'
  automatic_scaling = true
  nl_max_its = 40
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-7
[]

[Outputs]
  print_linear_residuals = false
[]