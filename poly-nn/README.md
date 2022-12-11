## PolyBench/polyNN

Deep Neural Networks (DNN) are well understood to be one of the largest consumers of HPC resources and efficiently running their training and inference phases on modern heterogeneous architectures (and accelerators) poses an important challenge for the compilation community. Currently, DNNs are actively being studied by the
automatic parallelization and polyhedral compilation communities for the same purpose. We study the kernels of four varieties of DNN layers with the goal of applying automatic parallelization techniques for latest architectures. 
We show the affine (Polyhedral) nature of these kernels thereby showing that they are amenable to well known polyhedral compilation techniques. 
For benchmarking purposes, we implemented forward and
backward kernels for four varieties of layers namely convolutional, pooling, recurrent and long short term memory in
PolyBench/C, a well known polyhedral benchmarking suite. We also evaluated our kernels on the state-of-art Pluto polyhedral compiler in order to highlight the speedups obtained by automatic loop transformations.

- Accepted at the 24th IEEE International Conference on High Performance Computing, Data, 
and Analytics **HiPC 2017** *(Poster)*. Link to the paper can be found [here](https://drive.google.com/open?id=1yEi5kYJ8E66EnTPiKz3OCS0kX7NFadPo)
