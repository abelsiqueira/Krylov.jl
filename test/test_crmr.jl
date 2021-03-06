function test_crmr()
  crmr_tol = 1.0e-4;  # We're tolerant just so random tests don't fail.

  function test_crmr(A, b; λ=0.0, M=opEye(size(A,1)))
    (nrow, ncol) = size(A);
    (x, stats) = crmr(A, b, λ=λ, M=M);
    r = b - A * x;
    if λ > 0
      s = r / sqrt(λ);
      r = r - sqrt(λ) * s;
    end
    resid = norm(r) / norm(b);
    @printf("CRMR: residual: %7.1e\n", resid);
    return (x, stats, resid)
  end

  # Underdetermined consistent.
  A = rand(10, 25); b = A * ones(25);
  (x, stats, resid) = test_crmr(A, b);
  @test(resid <= crmr_tol);
  @test(stats.solved);
  (xI, xmin, xmin_norm) = check_min_norm(A, b, x);
  @test(norm(xI - xmin) <= cond(A) * crmr_tol * xmin_norm);

  # Underdetermined inconsistent.
  A = ones(10, 25); b = rand(10); b[1] = -1.0;
  (x, stats, resid) = test_crmr(A, b);
  @test(stats.inconsistent);
  @test(stats.Aresiduals[end] <= crmr_tol);

  # Square consistent.
  A = rand(10, 10); b = A * ones(10);
  (x, stats, resid) = test_crmr(A, b);
  @test(resid <= crmr_tol);
  @test(stats.solved);
  (xI, xmin, xmin_norm) = check_min_norm(A, b, x);
  @test(norm(xI - xmin) <= cond(A) * crmr_tol * xmin_norm);

  # Square inconsistent.
  A = ones(10, 10); b = rand(10); b[1] = -1.0;
  (x, stats, resid) = test_crmr(A, b);
  @test(stats.inconsistent);
  @test(stats.Aresiduals[end] <= crmr_tol);

  # Overdetermined consistent.
  A = rand(25, 10); b = A * ones(10);
  (x, stats, resid) = test_crmr(A, b);
  @test(resid <= crmr_tol);
  @test(stats.solved);
  (xI, xmin, xmin_norm) = check_min_norm(A, b, x);
  @test(norm(xI - xmin) <= cond(A) * crmr_tol * xmin_norm);

  # Overdetermined inconsistent.
  A = ones(5, 3); b = rand(5); b[1] = -1.0;
  (x, stats, resid) = test_crmr(A, b);
  @test(stats.inconsistent);
  @test(stats.Aresiduals[end] <= crmr_tol);

  # With regularization, all systems are underdetermined and consistent.
  (x, stats, resid) = test_crmr(A, b, λ=1.0e-3);
  @test(resid <= crmr_tol);
  @test(stats.solved);
  (xI, xmin, xmin_norm) = check_min_norm(A, b, x, λ=1.0e-3);
  @test(norm(xI - xmin) <= cond(A) * crmr_tol * xmin_norm);

  # Code coverage.
  (x, stats, resid) = test_crmr(sparse(A), b, λ=1.0e-3);
  show(stats);

  # Test b == 0
  (x, stats) = crmr(A, zeros(size(A,1)))
  @test x == zeros(size(A,2))
  @test stats.status == "x = 0 is a zero-residual solution"

  # Test integer values
  A = [I; rand(1:10, 2, 3)]
  b = A * ones(Int, 3)
  (x, stats) = crmr(A, b)
  @test stats.solved

  # Test preconditioner with an under-determined problem:
  # Find the least norm force that transfers mass unit distance with zero final velocity
  A = 0.5 * [19.0 17.0 15.0 13.0 11.0 9.0 7.0 5.0 3.0 1.0;
              2.0  2.0  2.0  2.0  2.0 2.0 2.0 2.0 2.0 2.0]
  b = [1.0; 0.0]
  M = LinearOperator(Diagonal(1 ./ (A * A')))
  (x, stats, resid) = test_crmr(A, b, M=M)
  @test(resid ≤ crmr_tol)
  @test(stats.solved)
  (xI, xmin, xmin_norm) = check_min_norm(A, b, x)
  @test(norm(xI - xmin) ≤ cond(A) * crmr_tol * xmin_norm)
end

test_crmr()
