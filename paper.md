---
title: 'imaginarycss: An R package for Cognitive Social Structures'
tags:
  - R
  - social networks
  - cognitive social structures
  - perception
  - network analysis
authors:
  - name: Sima Najafzadehkhoei
    equal-contrib: true
    affiliation: 1
  - name: George Vega Yon
    equal-contrib: true
    affiliation: 1
  - name: Kyosuke Tanaka
    equal-contrib: false
    affiliation: 2
affiliations:
 - name: University of Utah, USA
   index: 1
 - name: Aarhus University, Denmark
   index: 2
date: 15 September 2025
bibliography: paper.bib
---

# Summary

`imaginarycss` is an R package for analyzing **Cognitive Social Structures** (CSS): multi-layer representations that record how each individual perceives the entire social network, not only their own ties. Because perceptions often drive decision-making, information flow, and influence, CSS data are central in sociology, organizational behavior, and social psychology.

The package provides efficient tools to represent CSS data, classify perceptual errors, compute tie-level accuracy measures, and generate null models for statistical testing. By implementing methods from recent research on imaginary structures and perceptual motifs, `imaginarycss` enables systematic study of discrepancies between observed networks and individuals' mental models.

# Statement of need

Despite decades of CSS scholarship [@KRACKHARDT1987109], there has been no reproducible, open-source toolkit tailored to perception-based network data. General network packages such as `statnet` [@JSSv024i01] and `igraph` [@article] offer powerful modeling and algorithmic capabilities, but they do not natively encode multiple overlapping perceptions of the same network. `ergmito` [@VEGAYON2021225] advances inference for very small networks, yet does not address perceptual error analysis.

`imaginarycss` fills this gap. It introduces a dedicated CSS data structure (`barry_graph`), functions to classify perceptual errors, measures that decompose accuracy, and simulation tools to build null distributions that preserve individual-level biases. These capabilities support principled, reproducible tests of hypotheses about perception, bias, and error in social networks.

# State of the field

Cognitive Social Structures research consistently reports systematic perceptual biases: people tend to overestimate reciprocity, under-detect asymmetric ties, and sometimes infer ties that do not exist. These regularities motivate methods that explicitly separate *perception* from *structure*. Recent work formalizes this idea via *imaginary motifs*—structural patterns of false positives and negatives emerging when perceived layers are compared to a ground-truth network [@TANAKA202465].

Although this literature provides a strong conceptual and statistical basis, empirical applications often rely on custom scripts, complicating replication and cross-study comparison. `imaginarycss` addresses this by: (i) standardizing multi-layer CSS representation; (ii) exposing a principled taxonomy and census of perceptual errors (including reciprocity-related misperceptions); (iii) decomposing tie-level accuracy into ego/alter and true-positive vs. true-negative components; and (iv) generating accuracy-preserving null models for hypothesis testing. By consolidating these capabilities in a single, open-source package, `imaginarycss` lowers the barrier to applied CSS research across sociology, psychology, and organizational science.

# Key features

Built on a performant C++ core with an R interface, `imaginarycss` combines efficient computation with an accessible API. Key capabilities include:

- **CSS-native data model**: The `barry_graph` object stores a ground-truth network and perceiver layers in a single, standardized structure.
- **Flexible inputs**: Create CSS objects from lists of adjacency matrices or block-diagonal matrices.
- **Comprehensive error taxonomy**: `count_imaginary_census()` assigns each dyad to a 10-category classification spanning null, asymmetric, and reciprocal cases; `count_recip_errors()` focuses on reciprocity.
- **Accuracy decomposition**: `tie_level_accuracy()` separates ego vs. alter and true-positive vs. true-negative components of perceptual accuracy.
- **Accuracy-based null models**: `sample_css_network()` generates simulated perceptions that preserve individual-level accuracy rates, supporting hypothesis tests against realistic baselines.
- **Performance and scale**: Core routines use vectorized, compiled code for interactive analysis on sizeable CSS datasets.
- **Ecosystem compatibility**: Complements `statnet`/ERGM modeling and `igraph` utilities; focuses on measurement and diagnostics of perception.

# Software description

- **Data structure**: `barry_graph` stacks adjacency matrices for the true network and each perceiver's network.
- **Error analysis**: `count_recip_errors()` quantifies reciprocity misperceptions; `count_imaginary_census()` classifies dyads into a 10-category taxonomy across null, asymmetric, and reciprocal cases.
- **Tie-level accuracy**: `tie_level_accuracy()` decomposes accuracy into ego vs. alter and true positive vs. true negative components.
- **Null models**: `sample_css_network()` simulates perceived networks using individual accuracy rates to construct realistic null distributions.
- **Performance**: Core routines are implemented in C++ for speed and scalability.

Together, these components provide a coherent pipeline from raw CSS data to interpretable diagnostics of perceptual bias and accuracy.

# Existing alternatives

Several R packages support network representation and modeling but are not CSS-specific. `imaginarycss` is complementary to these tools.

| Package             | CSS-Specific | Error Analysis | Accuracy Decomposition | Null Models | Primary Focus                                    |
|:--------------------|:------------:|:--------------:|:----------------------:|:-----------:|:-------------------------------------------------|
| `imaginarycss`      | ✓            | ✓              | ✓                      | ✓           | Perceptual errors and accuracy in CSS            |
| `statnet`           | ✗            | ✗              | ✗                      | ✗           | ERGMs; dynamic/network modeling; general tools   |
| `ergmito`           | ✗            | ✗              | ✗                      | ✗           | ERGM inference for very small networks           |
| `igraph`            | ✗            | ✗              | ✗                      | ✗           | Graph algorithms; community detection; viz       |

# Conclusion

`imaginarycss` is, to our knowledge, the first dedicated software framework for CSS analysis in R. By formalizing CSS data as `barry_graph` objects and providing tools for perceptual error classification, tie-level accuracy, and accuracy-based null models, the package improves reproducibility and accessibility of CSS research.

Crucially, `imaginarycss` complements the existing R ecosystem. Whereas `statnet` and `ergmito` emphasize structural modeling and inference, and `igraph` supplies general algorithms, `imaginarycss` focuses on **measurement and diagnosis of perception**. Using these tools together allows researchers to investigate both how networks are structured and how they are perceived—advancing theory in sociology, organizational science, and social cognition.

# Acknowledgements

We acknowledge contributions from...

# References