# ===================== fatigue_H_eta.i  pseudo hydrogen for diffuse HAZ =====================

[Mesh]
  file = weld5.inp
  uniform_refine = 0
  skip_partitioning = true
  construct_side_list_from_node_list = true
[]

[Variables]
  [./eta_HAZ]
    family = LAGRANGE
    order  = FIRST
  [../]
[]

[Kernels]
  # -∇·(∇eta_HAZ) = 0
  [./diff_eta]
    type     = ADDiffusion
    variable = eta_HAZ
  [../]
[]

[BCs]
  # 假设 line1 是靠 BM 一侧的 HAZ 外边界：eta_HAZ = 1
  [./eta_outer]
    type     = DirichletBC
    variable = eta_HAZ
    boundary = 'line1'
    value    = 1.0
  [../]

  # 假设 line2 是靠 WM 一侧的 HAZ 内边界：eta_HAZ = 0
  [./eta_inner]
    type     = DirichletBC
    variable = eta_HAZ
    boundary = 'line1-1'
    value    = 0.0
  [../]
  [./eta_outer1]
    type     = DirichletBC
    variable = eta_HAZ
    boundary = 'line2'
    value    = 1.0
  [../]

  # 假设 line2 是靠 WM 一侧的 HAZ 内边界：eta_HAZ = 0
  [./eta_inner1]
    type     = DirichletBC
    variable = eta_HAZ
    boundary = 'line2-2'
    value    = 0.0
  [../]
    [./eta_base]
    type     = DirichletBC
    variable = eta_HAZ
    boundary = 'base'
    value    = 1
  [../]
      [./eta_weld]
    type     = DirichletBC
    variable = eta_HAZ
    boundary = 'weld1 weld2'
    value    = 0
  [../]
[]

[Executioner]
  type = Steady
  solve_type = NEWTON

  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-17
  l_max_its  = 40
  petsc_options_iname = '-pc_type -snes_type'
  petsc_options_value = 'lu vinewtonrsls'
  automatic_scaling = true
[]

[Outputs]
  exodus   = true
  file_base = 'HAZ_marker'
[]
