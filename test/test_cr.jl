using Random

include("get_div_grad.jl")

function test_cr()
  cr_tol = 1.0e-6

  # Cubic spline matrix _ case: ‖x*‖ > Δ
  n = 10
  A = spdiagm(-1 => ones(n-1), 0 => 4 * ones(n), 1 => ones(n-1))
  b = A * [1:n;]

  (x, stats) = cr(A, b)
  r = b - A * x
  resid = norm(r) / norm(b)
  @printf("CR: Relative residual: %8.1e\n", resid)
  @test(resid <= cr_tol)
  @test(stats.solved)

  # Code coverage
  (x, stats) = cr(Matrix(A), b)
  show(stats)

  radius = 0.75 * norm(x)
  (x, stats) = cr(A, b, radius=radius)
  show(stats)
  @test(stats.solved)
  @test abs(norm(x) - radius) ≤ cr_tol * radius

  # Sparse Laplacian
  A = get_div_grad(16, 16, 16)
  b = randn(size(A, 1))
  itmax = 0
  # case: ‖x*‖ > Δ
  radius = 10.
  (x, stats) = cr(A, b, radius=radius)
  xNorm = norm(x)
  r = b - A * x
  resid = norm(r) / norm(b)
  @printf("CR: Relative residual: %8.1e\n", resid)
  @test abs(xNorm - radius) ≤ cr_tol * radius
  @test(stats.solved)
  # case: ‖x*‖ < Δ
  radius = 30.
  (x, stats) = cr(A, b, radius=radius)
  xNorm = norm(x)
  r = b - A * x
  resid = norm(r) / norm(b)
  @printf("CR: Relative residual: %8.1e\n", resid)
  @test(resid <= cr_tol)
  @test(stats.solved)

  radius = 0.75 * xNorm
  (x, stats) = cr(A, b, radius=radius)
  show(stats)
  @test(stats.solved)
  @test(abs(radius - norm(x)) <= cr_tol * radius)

  opA = LinearOperator(A)
  (xop, statsop) = cr(opA, b, radius=radius)
  @test(abs(radius - norm(xop)) <= cr_tol * radius)

  n = 100
  itmax = 2 * n
  B = LBFGSOperator(n)
  Random.seed!(0)
  for i = 1:5
    push!(B, rand(n), rand(n))
  end
  b = B * ones(n)
  (x, stats) = cr(B, b)
  @test norm(x - ones(n)) ≤ cr_tol * norm(x)
  @test stats.solved

  # Test b == 0
  (x, stats) = cr(A, zeros(size(A,1)))
  @test x == zeros(size(A,1))
  @test stats.status == "x = 0 is a zero-residual solution"

  # Test integer values
  A = [4 -1 0; -1 4 -1; 0 -1 4]
  b = [7; 2; -1]
  (x, stats) = cr(A, b)
  @test stats.solved

  # Test with Jacobi (or diagonal) preconditioner
  A = ones(10,10) + 9 * I
  b = 10 * [1:10;]
  M = 1/10 * opEye(10)
  (x, stats) = cr(A, b, M=M, itmax=10);
  show(stats)
  r = b - A * x;
  resid = norm(r) / norm(b);
  @printf("CR: Relative residual: %8.1e\n", resid);
  @test(resid <= cr_tol);
  # @test(stats.solved);
end

test_cr()
