functions {
  real icar_normal_lpdf(vector phi, int N, int[] node1, int[] node2) {
    return 0.5 * dot_self(phi[node1] - phi[node2])
      + normal_lpdf(sum(phi) | 0, 0.001 * N)
  }
} 
data {
  int<lower=0> N;
  int<lower=0> N_edges;
  int<lower=1, upper=N> node1[N_edges];
  int<lower=1, upper=N> node2[N_edges];
}
parameters {
  vector[N] phi;
}
model {
  phi ~ icar_normal_lpdf(N, node1, node2)
}