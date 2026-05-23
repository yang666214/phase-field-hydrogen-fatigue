# ===================== fatigue_H_C.i  Hydrogen transport SENT =====================
# PDE:  ∂C/∂t + ∇·[ -D ∇C + D * C * (V_H/(R*T0)) * ∇σ_h ] = 0
# IC:   C(x,0) = 0.1C
# BC:   C = C_env on TOP edge (boundary id 2); other edges = zero flux (natural)

# ---------- Mesh ----------
[Mesh]
  file = SENT10.inp
  uniform_refine = 0
  skip_partitioning = true
  construct_side_list_from_node_list=true
[]


# ---------- Primary variable ----------
[Variables]
  [./C]                            # Hydrogen concentration, mol/mm^3
    order  = FIRST
    family = LAGRANGE
  [../]
[]

# ---------- Fields received from main app ----------
[AuxVariables]
  [./sigma_h] order=FIRST family=LAGRANGE []   # hydrostatic stress (MPa), from main
  [./d]       order=FIRST family=LAGRANGE []   # 
[]

# ---------- Initial condition ----------
[ICs]
  [./C0]
    type = ConstantIC
    variable = C
    value = 7.86e-10 #0.1*(Cwppm * 1e-6) * rho_M / M_H  [mol/mm^3]
  [../]
[]

# ---------- Constants (units: mm, s, N, MPa, mol) ----------
T0       = 300           # K (no thermal coupling; constant temperature)
R_gas    = 8.314e3       # N·mm/(mol·K)
V_H      = 2000          # mm^3/mol (adjust)
D_L      = 1e-1          #mm^2/s   (adjust) 2e-1
rho_M    = 7.85e-6       # kg/mm^3  (steel)
M_H      = 1.008e-3      # kg/mol
Cwppm    = 1             #55 MPa = 0.571 wt-ppm            # wt-ppm of hydrogen at the gas-exposed Pre-crack edge (adjust)
k_mov    = 1e5           # numerical parameter 1e2
phi_th   = 0.95 
eps_step = 0.02          # Smoothing Width

# ---------- Surface concentration on TOP edge ----------
# C_env = (Cwppm * 1e-6) * rho_M / M_H  [mol/mm^3]
[Functions]
  [./C_env_fun]
    type = ParsedFunction
    value = '(Cwppm*1e-6) * rho_M / M_H'
    vars  = 'Cwppm rho_M M_H'
    vals  = '${Cwppm} ${rho_M} ${M_H}'   
  [../]
[]


# ---------- Materials ----------
[Materials]
  # Diffusivity
  [./D_H_mov]
    type = ADParsedMaterial
    property_name = 'D'
    #  step：0.5*(1+tanh((d-phi_th)/eps_step))
    expression = 'D_L*(1 + k_mov * (0.5*(1 + tanh((d - phi_th)/eps_step))))'
    coupled_variables = 'd'                   
    constant_names = 'D_L k_mov phi_th eps_step'
    constant_expressions = '${D_L} ${k_mov} ${phi_th} ${eps_step}'
  [../]

  # Stress-drift mobility factor beta = V_H / (R_gas*T0)
  [./beta_mat]
    type = ADParsedMaterial
    property_name = 'beta'
    expression = 'V_H / (R_gas*T0)'
    constant_names       = 'V_H R_gas T0'
    constant_expressions = '${V_H} ${R_gas} ${T0}'
    #outputs = exodus
  [../]
  # 把 D 和 beta 相乘成一个标量材性 D_beta
  [./D_beta]
  type = ADParsedMaterial
  property_name = 'D_beta'
  expression = 'D * beta'
  material_property_names = 'D beta'
  #outputs = exodus
  [../]

# 生成 v_drift = (D_beta) * grad(sigma_h)
  [./v_drift_from_grad_sigma]
  type = ADCoupledGradientMaterial
  coupled_variable = sigma_h
  gradient_material_name = v_drift        # 这个名字就是生成的“速度向量”材性名
  scalar_property_factor = D_beta         # 标量因子，把 D*beta 乘到 ∇sigma_h 上
  outputs = exodus
  [../]

[]

# ---------- Kernels ----------
[Kernels]
  # time derivative
  [./time]   type = ADTimeDerivative   variable = C []

  # Fickian diffusion: -∇·(D ∇C)
  [./diff]   type = ADMatDiffusion     variable = C   diffusivity = D []

  # stress-driven drift:  ∇·( D * C * beta * ∇sigma_h )
  # Conservative advection form with velocity v = D * beta * ∇sigma_h
  [./drift]
  type = ADConservativeAdvection
  variable = C
  velocity = v_drift     # 就是上面 Materials 产生的向量材性
  [../]
[]

# ---------- Boundary conditions ----------
[BCs] # h = External boundary, h1 = Pre-crack
  # C = C_env_fun
  [./C_on_mid_left]
    type     = FunctionDirichletBC    
    variable = C    
    boundary = 'Crack'
    function = C_env_fun   
  [../]     
[]


# ---------- Executioner ----------
[Executioner]
  type = Transient
  solve_type = NEWTON
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-7
  l_max_its  = 40
  petsc_options_iname = '-pc_type -snes_type'
  petsc_options_value = 'lu vinewtonrsls'
  automatic_scaling = true
  #[./TimeStepper]
  #  type = IterationAdaptiveDT
  #  dt = 1e-3
  #  growth_factor = 1.5
  #  cutback_factor = 0.3
  #[../]
[]

# ---------- Outputs ----------
[Outputs]
  exodus = true
  file_base = hydrogen_transport
  time_step_interval = 50
[]
