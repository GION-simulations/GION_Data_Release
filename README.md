# GION Data Release

Data release site for the **GION** multi-wavelength simulation suite.

This repository hosts the documentation, metadata tables, download scripts and tutorial notebooks for the public GION data products.

## Contents

- [GION Data Release](#gion-data-release)
  - [Contents](#contents)
  - [GION Quick Data Release (QDR)](#gion-quick-data-release-qdr)
  - [Repository layout](#repository-layout)
  - [Downloading the data](#downloading-the-data)
  - [Halo catalogues](#halo-catalogues)
  - [Convergence maps](#convergence-maps)
  - [Simulation setup and cosmology](#simulation-setup-and-cosmology)
  - [Tutorials](#tutorials)
  - [Full data set](#full-data-set)
  - [Citation and acknowledgement](#citation-and-acknowledgement)
  - [Change log](#change-log)
    - [Quick Data Release (QDR) — 2026-10-22](#quick-data-release-qdr--2026-10-22)

## GION Quick Data Release (QDR)

The Quick Data Release provides a first subset of the GION full-sky light-cone products from realization `r000`:

| Product | Redshift range | Format | Location | Total size |
| --- | --- | --- | --- | --- |
| Light-cone halo catalogues | 0.0 ≤ z ≲ 1.52 (24 shells) | HDF5 | `lc_halo_props/S080` – `lc_halo_props/S103` | 2.33 TB (14,004 files) |
| Weak-lensing convergence maps | 0.50 ≲ z_s ≲ 1.50 (69 source planes) | HEALPix FITS, Nside = 8192 | `lensing_maps/` | 445 GB (6.44 GB per map) |

The data are large: check the sizes below and your free disk space before downloading. Most analyses need only a few shells or maps.

## Repository layout

```text
.
├── README.md
├── download_halo.sh           # download script for halo catalogues
├── download_kappa.sh          # download script for convergence maps
├── z_halo.txt                 # redshift range of each halo shell (S080–S103)
├── halo_indices_ranges.txt    # file-index range of each halo shell
├── zs_kappa.txt               # source-redshift index -> source redshift
├── GION_lc_halo.ipynb         # tutorial: loading light-cone halos
├── GION_kappa.ipynb           # tutorial: loading convergence maps
└── cosmo/                     # simulation inputs (CLASS, monofonIC)
```

Downloaded data are placed in `lc_halo_props/` and `lensing_maps/`, which are ignored by git.

## Downloading the data

Two shell scripts are provided; they only need `curl` and a POSIX shell.

**Halo catalogues** — pass one or more shells (`S080`, …, `S103`) to [`download_halo.sh`](download_halo.sh):

```sh
sh download_halo.sh S100            # one shell
sh download_halo.sh S100 S101 S102  # several shells
sh download_halo.sh all             # every shell (2.33 TB)
```

All `halos.<i>.h5` files of each shell are saved in `lc_halo_props/<shell>/`.

**Convergence maps** — pass one or more source-plane indices (`zs_idx` = 95, …, 163) to [`download_kappa.sh`](download_kappa.sh):

```sh
sh download_kappa.sh 124            # one map
sh download_kappa.sh 95 124 163     # several maps
sh download_kappa.sh all            # every map (445 GB)
```

The maps are saved as `lensing_maps/GION_r000_kappa.<zs_idx>.fits`.

**Options and behaviour** (both scripts; run with `-h` for help):

- `-j N` sets the number of parallel downloads (default: 4), e.g. `sh download_halo.sh -j 8 S100`.
- Re-running a command is safe: complete files are skipped and interrupted files are resumed. If any file fails to download, the script reports it, exits with a non-zero status, and the same command can simply be run again.
- The data are saved next to the scripts by default, which is where the tutorial notebooks expect them. Set `GION_DATA_DIR` to save them elsewhere (e.g. a scratch disk): `GION_DATA_DIR=/path/to/scratch sh download_halo.sh S100`.
- `GION_BASE_URL` overrides the data server URL.

## Halo catalogues

The directory `lc_halo_props` contains light-cone halo catalogues in HDF5 format. The light cone is divided into 24 non-overlapping spherical shells centred on the observer, stored in directories `S080` (highest redshift) to `S103` (lowest redshift). Each shell is split into multiple files `halos.<i>.h5`, and the number of files and the size differ from shell to shell:

| Shell | Redshift range | Number of files | Size |
| --- | --- | --- | --- |
| `S080` | 1.48015 – 1.52283 | 729 | 120.9 GB |
| `S081` | 1.43661 – 1.48015 | 729 | 122.0 GB |
| `S082` | 1.39236 – 1.43661 | 729 | 122.6 GB |
| `S083` | 1.34764 – 1.39236 | 729 | 122.1 GB |
| `S084` | 1.30096 – 1.34764 | 729 | 125.4 GB |
| `S085` | 1.25415 – 1.30096 | 729 | 123.2 GB |
| `S086` | 1.20538 – 1.25415 | 729 | 125.7 GB |
| `S087` | 1.15673 – 1.20538 | 729 | 122.0 GB |
| `S088` | 1.10668 – 1.15673 | 729 | 121.7 GB |
| `S089` | 1.05466 – 1.10668 | 729 | 122.1 GB |
| `S090` | 0.99912 – 1.05466 | 729 | 125.1 GB |
| `S091` | 0.94201 – 0.99912 | 729 | 122.3 GB |
| `S092` | 0.88075 – 0.94201 | 729 | 123.4 GB |
| `S093` | 0.81595 – 0.88075 | 729 | 121.4 GB |
| `S094` | 0.74542 – 0.81595 | 729 | 120.6 GB |
| `S095` | 0.66554 – 0.74542 | 729 | 120.7 GB |
| `S096` | 0.57166 – 0.66554 | 729 | 119.8 GB |
| `S097` | 0.48183 – 0.57166 | 512 | 91.5 GB |
| `S098` | 0.39618 – 0.48183 | 343 | 66.2 GB |
| `S099` | 0.31437 – 0.39618 | 343 | 45.2 GB |
| `S100` | 0.23635 – 0.31437 | 216 | 27.9 GB |
| `S101` | 0.16210 – 0.23635 | 125 | 14.9 GB |
| `S102` | 0.09043 – 0.16210 | 64 | 6.2 GB |
| `S103` | 0.00000 – 0.09043 | 8 | 1.4 GB |
| **Total** | 0.00000 – 1.52283 | 14,004 | 2.33 TB |

The exact redshift range of each shell is listed in [`z_halo.txt`](z_halo.txt), and the file-index range in [`halo_indices_ranges.txt`](halo_indices_ranges.txt).

Each file has two groups:

- `Header` (attributes) — includes `Nfile` (number of files in the shell), `NumberHalos` (number of halos in this file; can be zero), `ComovingDistanceMin` / `ComovingDistanceMax` (shell boundaries in h⁻¹ Mpc), and the cosmological parameters `Omega_m` and `h`.
  > **Note:** the `Redshift` attribute (and the corresponding `ScaleFactor`) is **not** the redshift of the shell or of its halos. It is a temporary value taken from the simulation snapshot; do not use it.
- `Subhalo` (datasets) — halo properties, e.g. `Position` (comoving, h⁻¹ Mpc, observer at the origin) and `Mvir` (h⁻¹ M☉).

The data columns largely follow those of [MPI-Rockstar](https://github.com/Tomoaki-Ishiyama/mpi-rockstar/); refer to the [documentation](https://mpi-rockstar.readthedocs.io/en/latest/index.html) for the definition of each column. The catalogues do not store halo redshifts; compute them from the comoving distance (see [`GION_lc_halo.ipynb`](GION_lc_halo.ipynb)).

## Convergence maps

The directory `lensing_maps` contains full-sky weak-lensing convergence (κ) maps computed with the Born approximation. The maps are in HEALPix format with Nside = 8192.

- File name: `GION_r000_kappa.<zs_idx>.fits`
- `zs_idx` is the source-plane index; the corresponding source redshifts are listed in [`zs_kappa.txt`](zs_kappa.txt).
- Source planes are spaced every 25 h⁻¹ Mpc in comoving distance. The full set has 216 planes (`zs_idx` = 0–215, up to z_s ≈ 5.1); the QDR includes `zs_idx` = 95–163, i.e. z_s ≈ 1.505 – 0.504.
- Each map is 6.44 GB (double precision), so all 69 QDR maps total 445 GB. Loading one map needs a similar amount of memory.

## Simulation setup and cosmology

The directory [`cosmo`](cosmo/) contains the inputs used to generate the initial conditions:

| File | Description |
| --- | --- |
| [`input_class_parameters.ini`](cosmo/input_class_parameters.ini) | Input parameters for [CLASS](https://github.com/lesgourg/class_public) |
| [`input_transfer.txt`](cosmo/input_transfer.txt) | Transfer functions from CLASS |
| [`input_powerspec.txt`](cosmo/input_powerspec.txt) | Linear power spectra from CLASS |
| [`lightcone.conf`](cosmo/lightcone.conf) | Configuration for [monofonIC](https://bitbucket.org/ohahn/monofonic) |

Key parameters:

| Parameter | Value |
| --- | --- |
| Box size | 1500 h⁻¹ Mpc |
| Number of particles | 6144³ |
| Initial redshift | z = 24 (3LPT) |
| Cosmology | Planck 2018 (`Planck2018EE`) |
| h | 0.67321 |
| Ω_b | 0.049389 |
| Ω_cdm | 0.26499 |
| Σm_ν | 0.06 eV (one massive species) |
| A_s | 2.1005 × 10⁻⁹ |
| n_s | 0.96605 |

## Tutorials

| Notebook | Description | Requirements |
| --- | --- | --- |
| [`GION_lc_halo.ipynb`](GION_lc_halo.ipynb) | Read a halo shell, select massive halos, compute their redshifts, and plot them | `numpy`, `h5py`, `astropy`, `matplotlib` |
| [`GION_kappa.ipynb`](GION_kappa.ipynb) | Read and visualise a convergence map | `numpy`, `healpy`, `matplotlib` |

The notebooks assume the data have been downloaded into `lc_halo_props/` and `lensing_maps/` in the repository root. The data they use can be downloaded with `sh download_halo.sh S100` (27.9 GB) and `sh download_kappa.sh 124` (6.44 GB).

## Full data set

The QDR is a subset of the GION simulation suite. We will release the full dataset after the paper is accepted. If you need the full data set (e.g. other redshift ranges, full 10 realizations, maps of other observables) in advance, please contact Ken Osato ([ken.osato@chiba-u.jp](mailto:ken.osato@chiba-u.jp)).

## Citation and acknowledgement

If you use the GION data in your work, please cite the GION Overview paper:

> Osato et al., 2026 (arXiv:XXXX.XXXXX)

```bibtex
@article{GION,
  author  = {TBD},
  title   = {TBD},
  journal = {TBD},
  year    = {TBD},
  eprint  = {XXXX.XXXXX},
  archivePrefix = {arXiv}
}
```

and include the following acknowledgement:

> This work made use of data from the GION simulation suite (arXiv:XXXX.XXXXX).

## Change log

### Quick Data Release (QDR) — 2026-10-22

- Initial public release.
- Light-cone halo catalogues for 24 shells (`S080`–`S103`, 0 ≤ z ≲ 1.52).
- Born-approximation convergence maps for `zs_idx` = 95–163 (0.50 ≲ z_s ≲ 1.50), HEALPix Nside = 8192.
- CLASS and monofonIC input files.
- Download scripts and tutorial notebooks.
