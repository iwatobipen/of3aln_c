# of3aln_c

Docker file for MSA generation with OpenFold3

## Setup
- Clone repository and build docker image
```bash
$ git clone https://github.com/iwatobipen/of3aln_c.git
$ cd of3aln
$ docker build -f Dockerfile -t of3aln .
```
- Get MSA_Snakefile

```
wget https://raw.githubusercontent.com/aqlaboratory/openfold-3/refs/heads/main/scripts/snakemake_msa/MSA_Snakefile
```

## MSA generation
- Please read of3 documentation
- https://openfold-3.readthedocs.io/en/latest/precomputed_msa_generation_how_to.html
