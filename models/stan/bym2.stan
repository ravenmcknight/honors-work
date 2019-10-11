// credit to M. Morris, K. Wheeler-Martin, D. Simpson, et all

functions {
  real icar_normal_lpdf(vector phi, int N, int[] node1, int[] node2) {
    return -0.5 * dot_self(phi[node1] - phi[node2])
      + normal_lpdf(sum(phi) | 0, 0.001 * N);
 }
}
data {
  int<lower=0> N;
  int<lower=0> N_edges;
  int<lower=1, upper=N> node1[N_edges];  // node1[i], node2[i] neighbors
  int<lower=1, upper=N> node2[N_edges];  // node1[i] < node2[i]

  int<lower=0> y[N];             // count outcomes
  vector<lower=0>[N] E;          // exposure
  int<lower=1> K;                // num covariates
  matrix[N, K] x;                // design matrix
  real<lower=0> scaling_factor;  // scales the variance of the spatial effects
}
transformed data {
  vector[N] log_E = log(E);
}
parameters {
  real beta0;            // intercept
  vector[K] betas;       // covariates
  real logit_rho;

  vector[N] phi;         // spatial effects
  vector[N] theta;       // heterogeneous effects
  real<lower=0> sigma;   // overall standard deviation
}
transformed parameters {
  real<lower=0, upper=1> rho = inv_logit(logit_rho);
  vector[N] convolved_re = sqrt(rho / scaling_factor) * phi
                           + sqrt(1 - rho) * theta;
}
model {
  y ~ poisson_log(log_E + beta0 + x * betas + convolved_re * sigma);

  beta0 ~ std_normal();
  betas ~ std_normal();
  logit_rho ~ std_normal();
  sigma ~ std_normal();
  theta ~ std_normal();
  phi ~ icar_normal_lpdf(N, node1, node2);
}
generated quantities {
  vector[N] eta = log_E + beta0 + x * betas + convolved_re * sigma;
  vector[N] mu = exp(eta);
  int y_rep[N];
  if (max(eta) > 20) {
    // avoid overflow in poisson_log_rng
    print("max eta too big: ", max(eta));  
    for (n in 1:N)
      y_rep[n] = -1;
  } else {
      for (n in 1:N)
        y_rep[n] = poisson_log_rng(eta[n]);
  }
}