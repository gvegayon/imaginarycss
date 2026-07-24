---
title: '`imaginarycss`: Reproducible motif-based analysis of cognitive social structures in R'
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
date: 24 July 2026
keywords:
  - cognitive social structures
  - network perception
  - social network analysis
  - network motifs
  - R software
bibliography: paper.bib
---

# Abstract

Cognitive Social Structures (CSS) record how each member of a group perceives
the relations among all group members. They allow researchers to study not only
whether a report is accurate, but also whether perceptual errors form
recognizable local structures. Existing R software can represent stacks of
network reports and estimate consensus or latent criterion networks, but it
does not provide a direct implementation of the imaginary-motif census and its
associated conditional null model. We introduce `imaginarycss`, an open-source
R package that represents a criterion network and its perceptual layers,
classifies every directed dyad into a ten-category census, decomposes
perceiver-level accuracy by tie state and ego involvement, and simulates null
perceptions conditional on those estimated accuracy rates. Compiled counting
routines are exposed through a small R interface, with no data-management or
visualization framework required. We illustrate the workflow using empirical
friendship and advice network backbones from Krackhardt's high-technology
managers study and fixed synthetic perceptual layers distributed with the
package. The illustration recovers deliberately introduced reciprocity,
omission, and status-targeted commission mechanisms after conditioning on
overall accuracy. It demonstrates how motif analysis distinguishes the number
of errors from their structural arrangement; it is not an empirical analysis
of the managers' perceptions. `imaginarycss` is available from CRAN under an
MIT license.

# 1. Introduction

A conventional social-network study asks which relations connect the members
of a group. A Cognitive Social Structure (CSS) study additionally asks how
each group member believes every other pair to be connected. For a group of
$n$ actors, a complete CSS can therefore be represented as an
$n \times n \times n$ array: one $n \times n$ network layer for each
perceiver [@KRACKHARDT1987109]. This design separates the relational structure
used as a criterion from the mental representations through which actors make
decisions.

That distinction is substantively important. Network perceptions are
systematically related to social position, personality, and organizational
outcomes, and biased perceptions can themselves influence action
[@CASCIARO1998; @BRANDS2013]. A scalar accuracy score, however, cannot say
whether errors are scattered or organized. Two perceivers can have the same
false-positive and false-negative rates while differing sharply in whether
they imagine reciprocity, reverse the direction of asymmetric relations, or
concentrate errors around particular dyadic states.

Imaginary network motifs address this problem by classifying combinations of
accurately and inaccurately perceived ties within local structures
[@TANAKA202465]. The dyadic imaginary census is the first level of that
framework. It distinguishes ten combinations of a criterion dyad and its
perceived counterpart, including partial, complete, and mixed errors. The
published framework provides the concepts and statistical motivation;
`imaginarycss` provides a reusable implementation.

The package occupies a specific position in the R network ecosystem. The
`sna` package already accepts graph stacks, converts row-wise reports to CSS
form with `sr2css()`, estimates consensus structures, and implements Bayesian
network-accuracy models with `bbnam()` [@BUTTS2008]. The `statnet` suite
supports general network representation and statistical modeling
[@JSSv024i01], while `igraph` supplies general graph algorithms
[@article]. These are important complements, not absent alternatives.
`imaginarycss` differs by focusing on the *topology of perceptual error
conditional on a user-supplied criterion network*: the imaginary census,
ego/alter accuracy decomposition, and an accuracy-conditioned simulation
workflow. It does not estimate which criterion network is correct.

This paper has three goals. First, it defines the quantities computed by the
package and the assumptions of its null model. Second, it describes the
software workflow and its relationship to existing tools. Third, it uses a
controlled, semi-synthetic example to show what the census detects beyond
perceiver-level accuracy.

# 2. Imaginary dyads and the conditional null model

## 2.1. Criterion and perceptual layers

Let $G^{(0)}$ denote a binary, directed criterion network on a common actor
set $V$, and let $G^{(k)}$ denote actor $k$'s perception of that network.
The word *criterion* is deliberate. In many CSS studies there is no
objectively observed ground truth: the comparison network may be based on
own-report aggregation, a locally aggregated structure, consensus, or a
statistical estimate. `imaginarycss` conditions on the network supplied as
$G^{(0)}$; the researcher remains responsible for defining and justifying
it.

For each unordered actor pair $\{i,j\}$, the criterion dyad is one of three
types: null $(0,0)$, asymmetric $(1,0)$ or $(0,1)$, or reciprocal
$(1,1)$. Comparing it with the corresponding entries of $G^{(k)}$ produces
the ten mutually exclusive categories in Table 1. Every
perceiver--dyad observation belongs to exactly one category, so the counts
retain both the direction and joint organization of false positives and false
negatives.

**Table 1. Ten-category dyadic imaginary census.**

| Criterion dyad | Perceived dyad | Census category | Interpretation |
|:---|:---|:---|:---|
| Null | Null | Accurate null | Both absent ties are correctly perceived |
| Null | Asymmetric | Partial false positive (null) | One nonexistent direction is added |
| Null | Reciprocal | Complete false positive (null) | Both nonexistent directions are added |
| Asymmetric | Null | Partial false negative (asymmetric) | The existing direction is omitted |
| Asymmetric | Same direction | Accurate asymmetric | Both directions are correctly perceived |
| Asymmetric | Opposite direction | Mixed asymmetric | One false negative and one false positive |
| Asymmetric | Reciprocal | Partial false positive (asymmetric) | The existing tie is retained and its reverse is added |
| Reciprocal | Null | Complete false negative (reciprocal) | Both existing directions are omitted |
| Reciprocal | Asymmetric | Partial false negative (reciprocal) | One existing direction is omitted |
| Reciprocal | Reciprocal | Accurate reciprocal | Both existing directions are correctly perceived |

`count_imaginary_census()` returns these counts by perceiver. Its
`counter_type` argument can restrict the census to dyads involving the
perceiver (`counter_type = 1L`) or to alter--alter dyads
(`counter_type = 2L`). `count_recip_errors()` offers a smaller classification
focused on reciprocity-related omissions, commissions, and mixed errors.

## 2.2. Four accuracy rates

`tie_level_accuracy()` separates sensitivity and specificity along two
dimensions: whether a criterion tie is present and whether the dyad involves
the perceiver. Let $g$ be either `ego` for ordered pairs incident to
perceiver $k$, or `alter` for ordered pairs between other actors. The package
estimates

$$
p^{(k)}_{1,g}
=
\Pr\!\left(G^{(k)}_{ij}=1 \mid G^{(0)}_{ij}=1,\; (i,j)\in g\right)
$$

and

$$
p^{(k)}_{0,g}
=
\Pr\!\left(G^{(k)}_{ij}=0 \mid G^{(0)}_{ij}=0,\; (i,j)\in g\right).
$$

Thus $p_{1,\mathrm{ego}}$ and $p_{1,\mathrm{alter}}$ are
true-positive rates, while $p_{0,\mathrm{ego}}$ and
$p_{0,\mathrm{alter}}$ are true-negative rates. The decomposition avoids
conflating knowledge of one's own relations with knowledge of relations among
others, and it avoids allowing abundant non-ties to dominate a single
accuracy score.

## 2.3. Accuracy-conditioned simulation

`sample_css_network()` uses the four estimated rates for each perceiver as
Bernoulli probabilities. Conditional on $G^{(0)}$, the perceiver, and whether
an ordered pair is ego-involved or alter-only, a criterion tie is sampled as
present with probability $p^{(k)}_{1,g}$, while a criterion non-tie is
sampled as present with probability $1-p^{(k)}_{0,g}$. Ordered pairs are
independent under this null.

The simulated layers consequently reproduce each perceiver's four accuracy
rates *in expectation*. They do not condition on the exact realized numbers
of true positives, true negatives, false positives, and false negatives. This
null asks whether the locations and dyadic combinations of errors contain
more structure than expected from the criterion network and heterogeneous
perceiver accuracy alone.

`test_imaginary_census()` repeatedly samples a full CSS under this model,
recomputes the ten counts, and compares each observed total $C_m$ with its
simulation distribution:

$$
z_m
=
\frac{C_m-\overline{C_m^{*}}}
     {\operatorname{sd}(C_m^{*})}.
$$

The returned object contains the observed counts, the complete simulation
matrix, null means and standard deviations, $z$-scores, raw empirical
two-sided tail areas, and a nominal significance indicator. The ten counts
are dependent and compositional. For confirmatory use, researchers should
choose a sufficiently large simulation count, pre-specify contrasts where
possible, and address multiplicity rather than interpreting ten nominal tests
as independent.

# 3. Software design and workflow

## 3.1. Data representation and implementation

The central `barry_graph` object stores the criterion network followed by its
perceptual layers in a block-diagonal binary-array representation. Users can
construct it from a list of equal-sized adjacency matrices or from a single
block-diagonal matrix. The standard CSS workflow assumes that perceptual layer
$k$ belongs to actor $k$, and that all layers share the same ordered actor
set.

Counting routines are implemented in C++ and exposed through `Rcpp`
[@RCPP2011]. The underlying binary-array counters use the header-only `barry`
library [@BARRY2025]. At the R level, the analysis is organized around a small
set of functions:

| Function | Role |
|:---|:---|
| `new_barry_graph()` | Combine a criterion matrix and perceptual layers |
| `barray_to_edgelist()` | Recover a conventional edge-list representation |
| `count_imaginary_census()` | Count the ten dyadic categories by perceiver |
| `count_recip_errors()` | Count reciprocity-specific error categories |
| `tie_level_accuracy()` | Estimate four accuracy rates per perceiver |
| `sample_css_network()` | Draw perceptions under the conditional null |
| `test_imaginary_census()` | Compare observed and simulated census totals |
| `plot()` | Display motif $z$-scores using base R graphics |

The runtime interface depends only on `Rcpp`, `stats`, and base graphics.
General manipulation, modeling, and visualization can therefore be performed
with `sna`, `statnet`, `igraph`, or other tools before or after the
CSS-specific diagnostic step. `ergmito`, for example, addresses likelihood
inference for very small networks [@VEGAYON2021225], whereas
`imaginarycss` addresses the measurement and arrangement of perceptual error.

## 3.2. Constructing an analysis

The following code, adapted from the package vignettes, converts the bundled
edge-list data to integer adjacency matrices and combines each reference
network with its 21 fixed synthetic perception layers.

```r
library(imaginarycss)

df_to_adjmat <- function(x) {
  n <- max(c(x$from, x$to))
  ans <- matrix(0L, nrow = n, ncol = n)
  ans[cbind(x$from, x$to)] <- as.integer(x$value)
  diag(ans) <- 0L
  ans
}

integer_matrix <- function(x) {
  storage.mode(x) <- "integer"
  x
}

friendship_graph <- new_barry_graph(c(
  list(df_to_adjmat(krackhardt_friendship)),
  lapply(krackhardt_friendship_perceptions, integer_matrix)
))

advice_graph <- new_barry_graph(c(
  list(df_to_adjmat(krackhardt_advice)),
  lapply(krackhardt_advice_perceptions, integer_matrix)
))
```

The same constructors accept a researcher's own criterion and CSS matrices.
The package treats any nonzero entry as a tie; explicit integer $0/1$
matrices make the intended binary analysis unambiguous.

# 4. Controlled Krackhardt-based illustration

## 4.1. Data and validation question

The package includes friendship and advice reference networks for 21 managers
in a high-technology organization [@KRACKHARDT1987109]. The friendship
reference has 102 directed arcs (density 0.243), and the advice reference has
190 arcs (density 0.452).

The objects `krackhardt_friendship_perceptions` and
`krackhardt_advice_perceptions` require a different provenance statement.
They are not the 21 managers' reported CSS layers. They are fixed synthetic
layers created over the empirical network backbones and distributed as
example data. Their generator introduced three mechanisms for each of 21
synthetic perceivers:

1. a criterion non-tie directed toward an actor with above-median indegree
   could become a false positive with probability 0.15;
2. the absent reverse of a criterion asymmetric tie could be added with
   probability 0.30; and
3. a criterion tie could be omitted with probability 0.20.

The analysis below therefore asks a software-validation question: after
conditioning on the four realized accuracy rates, does the imaginary census
recover the deliberately structured placement of errors? Because the
perceptual layers are synthetic, the results support neither claims about
individual managers nor population claims about human cognition.

## 4.2. Accuracy

The four mean rates show why raw error totals are an incomplete comparison.
The sparser friendship example has higher true-positive and true-negative
rates than the advice example, but the ego/alter means are similar within
each relation.

```r
friendship_accuracy <- tie_level_accuracy(friendship_graph)
advice_accuracy <- tie_level_accuracy(advice_graph)

mean_accuracy <- function(x) {
  colMeans(x[, c("p_0_ego", "p_1_ego",
                 "p_0_alter", "p_1_alter")],
           na.rm = TRUE)
}

round(rbind(
  Friendship = mean_accuracy(friendship_accuracy),
  Advice = mean_accuracy(advice_accuracy)
), 3)
```

**Table 2. Mean perceiver-level accuracy rates.**

| Relation | True negative, ego | True positive, ego | True negative, alter | True positive, alter |
|:---|---:|---:|---:|---:|
| Friendship | 0.886 | 0.750 | 0.886 | 0.762 |
| Advice | 0.795 | 0.695 | 0.794 | 0.701 |

## 4.3. Motif deviations

We used 1,000 null samples. Setting the seed and retaining the call order
below reproduces Table 3 from package version 0.1.0.

```r
set.seed(331)

friendship_test <- test_imaginary_census(
  friendship_graph,
  n_sim = 1000L
)
advice_test <- test_imaginary_census(
  advice_graph,
  n_sim = 1000L
)

plot(friendship_test, main = "Friendship")
plot(advice_test, main = "Advice")
```

There are $21 \times \binom{21}{2}=4{,}410$ perceiver--dyad classifications
for each relation. Table 3 reports every observed category total and its
standardized deviation from the accuracy-conditioned null. We emphasize the
direction and magnitude of the deviations rather than raw Monte Carlo
$p$-values.

**Table 3. Observed imaginary-census totals and null-model $z$-scores.**

| Census category | Friendship observed | Friendship $z$ | Advice observed | Advice $z$ |
|:---|---:|---:|---:|---:|
| Accurate null | 2,472 | 14.98 | 992 | 7.05 |
| Partial false positive (null) | 276 | -13.55 | 343 | -5.55 |
| Complete false positive (null) | 3 | -5.80 | 30 | -3.81 |
| Partial false negative (asymmetric) | 171 | -5.72 | 463 | -1.88 |
| Accurate asymmetric | 529 | -16.49 | 1,052 | -5.08 |
| Mixed asymmetric | 98 | 11.50 | 173 | 3.90 |
| Partial false positive (asymmetric) | 378 | 27.99 | 412 | 6.88 |
| Complete false negative (reciprocal) | 33 | 0.56 | 81 | -0.50 |
| Partial false negative (reciprocal) | 181 | 0.76 | 395 | 0.21 |
| Accurate reciprocal | 269 | -1.01 | 469 | 0.09 |

The largest positive departure in both relations is the partial false
positive on an asymmetric criterion dyad. This is the census signature
expected when the reverse of an asymmetric tie is preferentially added. The
corresponding deficit of accurately perceived asymmetric dyads points in the
same direction. Mixed asymmetric errors are also overrepresented, consistent
with interactions between tie omissions and reverse-tie additions.

The null model distributes false positives across eligible criterion
non-ties according to each perceiver's overall rates. The synthetic generator
instead concentrates one class of commissions on high-indegree recipients.
Consequently, most null dyads remain completely accurate more often than the
conditional null expects, while partial and complete false positives on null
dyads are underrepresented. The stronger standardized departures for the
friendship backbone reflect the combination of the same generating rules with
a different density and dyadic opportunity structure.

This example shows the distinction the software is designed to make. The
accuracy table describes *how many* ties and non-ties were correctly
perceived; the imaginary census describes *how the errors were arranged*.
Because the arrangement was deliberately introduced, the result is a
mechanism-recovery illustration rather than an independent empirical finding.

# 5. Validation, scope, and limitations

The package uses `tinytest` for automated checks. The current suite verifies
perfect-accuracy and edge-case behavior of the sampler, finite sampling
probabilities when some accuracy components are undefined, conservation of
census totals under aggregation, the structure of returned test objects, and
execution of print, summary, and plot methods. The controlled example adds an
end-to-end check that deliberately non-uniform errors produce the expected
qualitative census signatures. It is not a simulation study of test size or
power, and we do not present a performance benchmark here.

Several boundaries are important when interpreting results:

- **The criterion is fixed.** Uncertainty created by choosing among
  own-report, locally aggregated, consensus, or model-based criterion networks
  is not propagated. A useful workflow can estimate candidate criteria with
  `sna` and repeat the imaginary census as a sensitivity analysis.
- **The current data model is binary and directed.** Valued, signed, and
  uncertain ties require prior dichotomization or a future extension.
- **Actors and perceivers are aligned.** The accuracy decomposition assumes a
  common actor set, consistently ordered layers, and one perceptual layer per
  actor. Missing informants and missing dyadic reports are not explicitly
  modeled.
- **Accuracy is matched in expectation.** The Bernoulli null does not preserve
  exact confusion-matrix margins, and it treats the estimated accuracy rates
  as known. An exact conditional sampler or a hierarchical model would answer
  a different, and often useful, question.
- **Null dyads are conditionally independent.** Deviations can reveal
  patterned error, but a large $z$-score does not by itself identify a
  unique cognitive mechanism.
- **The categories are dependent.** Raw tail areas from ten simultaneous
  comparisons should not be treated as independent confirmatory tests.
- **The illustration is semi-synthetic.** It demonstrates the software and
  recovery of imposed mechanisms, not the perceptions of Krackhardt's
  managers.

These limitations also identify natural extensions: support for uncertain
criterion networks, exact-margin null models, missing or valued CSS data,
higher-order imaginary motifs, and calibrated simulation studies across
network size and density.

# 6. Availability and reproducibility

`imaginarycss` version 0.1.0 is available from CRAN with the persistent
identifier <https://doi.org/10.32614/CRAN.package.imaginarycss>
[@IMAGINARYCSS2026]. Development takes place at
<https://github.com/gvegayon/imaginarycss>. The source is released under the
MIT license. The reference networks, fixed synthetic perception layers, and
the code needed to reproduce the analysis are distributed with the package
and its vignettes.

# 7. Conclusion

`imaginarycss` turns the imaginary-motif framework into a concise,
reproducible R workflow. Its contribution is not another general graph
container or a method for estimating a criterion network. It complements
those tools by measuring the local topology of disagreement between a chosen
criterion and actor-specific perceptions, then comparing that topology with a
null model conditioned on heterogeneous accuracy. The controlled example
shows why this matters: equal or similar accuracy rates can conceal sharply
non-random organizations of false positives and false negatives.

By making the census, accuracy decomposition, simulation, and visualization
available through a single open-source interface, the package lowers the cost
of replicating imaginary-structure analyses and comparing perceptual patterns
across relations and studies. Its most immediate use is diagnostic; its
longer-term value is as a building block connecting criterion-network
estimation, network cognition, and formal tests of patterned perceptual error.

# Acknowledgements

[To be completed by the authors before submission.]

# Statements and declarations

**Funding.** [To be completed by the authors.]

**Competing interests.** [To be completed by the authors.]

**Author contributions.** [To be completed by the authors.]

**Data and code availability.** All software and example inputs used in this
paper are available from CRAN and the public source repository listed above.

# References
