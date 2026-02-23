#' Summarize an imaginary census
#'
#' Aggregates the per-perceiver motif counts returned by
#' [count_imaginary_census()] into totals per motif type.
#'
#' @param object A data frame returned by [count_imaginary_census()].
#' @param ... Currently ignored.
#'
#' @return A named numeric vector with total counts per motif type (sorted in
#'   decreasing order).
#'
#' @examples
#' # Create example networks
#' true_net <- matrix(c(0, 1, 1, 0,
#'                      1, 0, 0, 1,
#'                      1, 0, 0, 1,
#'                      0, 1, 1, 0), nrow = 4, byrow = TRUE)
#' person1 <- matrix(c(0, 1, 0, 0,
#'                     1, 0, 1, 1,
#'                     0, 1, 0, 0,
#'                     0, 1, 0, 0), nrow = 4, byrow = TRUE)
#' person2 <- matrix(c(0, 1, 1, 1,
#'                     1, 0, 0, 0,
#'                     1, 0, 0, 1,
#'                     1, 0, 1, 0), nrow = 4, byrow = TRUE)
#' graph <- new_barry_graph(list(true_net, person1, person2))
#' census <- count_imaginary_census(graph)
#' summary(census)
#'
#' @export
summary.imaginary_census <- function(object, ...) {

  agg <- .aggregate_motifs(object)
  sort(agg, decreasing = TRUE)

}

#' Test imaginary census motifs against a null model
#'
#' Generates a null distribution of imaginary-census motif counts by
#' repeatedly sampling CSS networks with [sample_css_network()] and compares
#' the observed counts to this null distribution. Returns an S3 object of
#' class `"imaginarycss_test"` with `print`, `summary`, and `plot` methods.
#'
#' @param graph A `barry_graph` object.
#' @param n_sim Integer. Number of null-model simulations (default `100`).
#' @param alpha Numeric. Significance level for the two-sided test
#'   (default `0.05`).
#' @param counter_type Integer passed to [count_imaginary_census()]
#'   (default `0L`).
#'
#' @return An object of class `"imaginarycss_test"`, which is a list
#'   containing:
#' \describe{
#'   \item{results}{A data frame with columns `motif`, `observed`,
#'     `null_mean`, `null_sd`, `z_score`, `p_value`, and `significant`.}
#'   \item{observed}{Named numeric vector of observed motif totals.}
#'   \item{null_matrix}{Matrix of null motif totals (motifs x simulations).}
#'   \item{n_sim}{Number of simulations used.}
#'   \item{alpha}{Significance level used.}
#' }
#'
#' @examples
#' true_net <- matrix(c(0, 1, 1, 0,
#'                      1, 0, 0, 1,
#'                      1, 0, 0, 1,
#'                      0, 1, 1, 0), nrow = 4, byrow = TRUE)
#' person1 <- matrix(c(0, 1, 0, 0,
#'                     1, 0, 1, 1,
#'                     0, 1, 0, 0,
#'                     0, 1, 0, 0), nrow = 4, byrow = TRUE)
#' person2 <- matrix(c(0, 1, 1, 1,
#'                     1, 0, 0, 0,
#'                     1, 0, 0, 1,
#'                     1, 0, 1, 0), nrow = 4, byrow = TRUE)
#' graph <- new_barry_graph(list(true_net, person1, person2))
#' res <- test_imaginary_census(graph, n_sim = 50)
#' res
#' summary(res)
#' plot(res)
#'
#' @export
test_imaginary_census <- function(
    graph,
    n_sim        = 100L,
    alpha        = 0.05,
    counter_type = 0L
) {

  stopifnot_barry_graph(graph)

  # --- Observed motif totals ---
  census_obs  <- count_imaginary_census(graph, counter_type)
  observed    <- .aggregate_motifs(census_obs)

  # --- Null distribution ---
  null_matrix <- replicate(n_sim, {
    .aggregate_motifs(
      count_imaginary_census(
        new_barry_graph(sample_css_network(graph)),
        counter_type
      )
    )
  })

  # --- Significance tests ---
  motifs   <- names(observed)
  obs      <- as.numeric(observed)
  null_mat <- null_matrix[motifs, , drop = FALSE]
  null_mu  <- rowMeans(null_mat)
  null_sd  <- apply(null_mat, 1, sd)

  z_score <- ifelse(null_sd > 0, (obs - null_mu) / null_sd, 0)
  p_value <- 2 * pmin(
    rowMeans(null_mat <= obs),
    rowMeans(null_mat >= obs)
  )

  results <- data.frame(
    motif       = motifs,
    observed    = as.integer(obs),
    null_mean   = round(null_mu, 1),
    null_sd     = round(null_sd, 2),
    z_score     = round(z_score, 2),
    p_value     = round(p_value, 4),
    significant = abs(z_score) > stats::qnorm(1 - alpha / 2) &
                  p_value < alpha,
    row.names   = NULL,
    stringsAsFactors = FALSE
  )

  structure(
    list(
      results     = results,
      observed    = observed,
      null_matrix = null_matrix,
      n_sim       = n_sim,
      alpha       = alpha
    ),
    class = "imaginarycss_test"
  )
}

#' @rdname test_imaginary_census
#' @param x An object of class `"imaginarycss_test"`.
#' @param ... Currently ignored.
#' @export
print.imaginarycss_test <- function(x, ...) {

  cat("Imaginary-census significance test\n")
  cat("  Simulations:", x$n_sim, " | Alpha:", x$alpha, "\n\n")

  sig <- x$results[x$results$significant, , drop = FALSE]
  if (nrow(sig) > 0L) {
    cat("Significant motifs:\n")
    print(sig[order(-abs(sig$z_score)),
              c("motif", "observed", "z_score", "p_value")],
          row.names = FALSE)
  } else {
    cat("No significant deviations from the null model.\n")
  }

  invisible(x)
}

#' @rdname test_imaginary_census
#' @param object An object of class `"imaginarycss_test"`.
#' @export
summary.imaginarycss_test <- function(object, ...) {

  n_sig    <- sum(object$results$significant)
  n_motifs <- nrow(object$results)

  cat("Imaginary-census significance test\n")
  cat("  Simulations:", object$n_sim, " | Alpha:", object$alpha, "\n")
  cat("  Motifs tested:", n_motifs,
      "| Significant:", n_sig, "\n\n")

  print(
    object$results[
      order(-abs(object$results$z_score)),
      c("motif", "observed", "null_mean", "null_sd",
        "z_score", "p_value", "significant")
    ],
    row.names = FALSE
  )

  invisible(object)
}

#' @rdname test_imaginary_census
#' @param main Character. Plot title.
#' @export
#' @importFrom graphics barplot abline par
plot.imaginarycss_test <- function(x, main = "Motif Z-Scores vs Null", ...) {

  res  <- x$results[order(x$results$z_score), ]
  cols <- ifelse(res$significant, "steelblue", "grey80")
  z_crit <- stats::qnorm(1 - x$alpha / 2)

  old_par <- par(mar = c(4, 12, 3, 1))
  on.exit(par(old_par))

  barplot(
    res$z_score,
    horiz     = TRUE,
    las       = 1,
    names.arg = res$motif,
    col       = cols,
    border    = NA,
    xlab      = "Z-Score",
    main      = main,
    ...
  )
  abline(v = c(-z_crit, z_crit), lty = 2, col = "red")
  abline(v = 0, col = "grey50")

  invisible(x)
}

# -- internal helper -----------------------------------------------------------

#' Aggregate imaginary census counts by motif type
#' @noRd
.aggregate_motifs <- function(census) {
  motif <- gsub("\\([0-9]+\\)\\s*", "", census$name)
  res   <- tapply(census$value, motif, sum)
  # Convert from 1-d array to plain named vector
  setNames(as.numeric(res), names(res))
}
