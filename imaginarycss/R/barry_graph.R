#' Convert to Integer
#' 
#' @description
#' Converts input to integer while preserving dimensions and checking for 
#' non-integer values.
#' 
#' @param x Numeric vector or matrix to convert to integer.
#' 
#' @return
#' Integer vector or matrix with same dimensions as input.
#' 
#' @details
#' This function checks that all values in the input are integers (within
#' machine precision) before converting. If any values are not integers,
#' an error is thrown. For matrices, the dimension attribute is preserved.
#' 
#' @examples
#' # Convert numeric vector to integer
#' to_integer(c(1, 2, 3))
#' to_integer(c(1.0, 2.0, 3.0))
#' 
#' # Convert matrix to integer
#' mat <- matrix(c(1, 0, 1, 0), nrow = 2)
#' to_integer(mat)
#' 
#' # Example with adjacency matrix
#' adj_mat <- matrix(c(0, 1, 0, 1, 0, 1, 0, 1, 0), nrow = 3)
#' to_integer(adj_mat)
#' 
#' @keywords internal
to_integer <- function(x) {
  fcall <- as.character(match.call()[[2]])
  if (any(abs(round(x) - x) > .Machine$double.eps ^ 0.5))
    stop("Values in ", fcall, " must be integer")
  # Case of a vector 
  if (!length(dim(x))) {
    as.integer(x)
  }
  # Case of a matrix
  structure(
    as.integer(x),
    dim = dim(x)
  )
}

#' Binary Array Graph
#' @param x Either a matrix or a list of matrices.
#' @param ... Currently ignored. 
#' @export
#' @aliases barry_graph
#' @examples
#' # Create a simple 3x3 network
#' net1 <- matrix(c(0, 1, 0,
#'                  1, 0, 1,
#'                  0, 1, 0), nrow = 3, byrow = TRUE)
#' 
#' # Create another 3x3 network (someone's perception)
#' net2 <- matrix(c(0, 1, 1,
#'                  1, 0, 0,
#'                  1, 0, 0), nrow = 3, byrow = TRUE)
#' 
#' # Method 1: Using a list of matrices
#' networks_list <- list(net1, net2)
#' graph1 <- new_barry_graph(networks_list)
#' print(graph1)
#' 
#' # Method 2: Using a block diagonal matrix
#' block_matrix <- rbind(
#'   cbind(net1, matrix(0, 3, 3)),
#'   cbind(matrix(0, 3, 3), net2)
#' )
#' graph2 <- new_barry_graph(block_matrix, n = 3)
#' print(graph2)
new_barry_graph <- function(x, ...) UseMethod("new_barry_graph")

#' @export
#' @param n Integer. The size of the original network.
#' @details
#' When `x` is a matrix, it is assumed that it will be a block
#' diagonal matrix, with the first block corresponding to the reference
#' (true) network. 
#' 
#' If `x` is a list, the first matrix is assumed to be the reference
#' (true) network.
#' 
#' @examples
#' # Example with block diagonal matrix
#' # Create two 4x4 networks
#' true_net <- matrix(c(0, 1, 1, 0,
#'                      1, 0, 0, 1,
#'                      1, 0, 0, 1,
#'                      0, 1, 1, 0), nrow = 4, byrow = TRUE)
#' 
#' perceived_net <- matrix(c(0, 1, 0, 0,
#'                          1, 0, 1, 1,
#'                          0, 1, 0, 0,
#'                          0, 1, 0, 0), nrow = 4, byrow = TRUE)
#' 
#' # Combine into block diagonal matrix
#' block_diag <- matrix(0, 8, 8)
#' block_diag[1:4, 1:4] <- true_net
#' block_diag[5:8, 5:8] <- perceived_net
#' 
#' # Create barry graph
#' graph <- new_barry_graph(block_diag, n = 4)
#' print(graph)
#' 
#' @rdname new_barry_graph
new_barry_graph.matrix <- function(x, n, ...) {
  
  # Checking that size matches n
  if (diff(dim(x)) != 0L)
    stop("-x- must be a square matrix.", call. = FALSE)
  
  # This must be evenly able to divide
  N <- nrow(x)
  if (N %% n)
    stop("The modulo between nrow(x) and n is not zero.", call. = FALSE)
  
  if (n < 1L)
    stop("-n- cannot less than 1L", call. = FALSE)
  
  # Identifying the endpoints
  n <- as.integer(n)
  n_nets    <- as.integer(N %/% n)
  # It cannot be a single network
  if (n_nets < 2L)
    stop("The number of networks must be at least 2L.", call. = FALSE)
  endpoints <- cumsum(rep(n, times = n_nets - 1L)) + n
  
  edgelist <- which(x != 0L, arr.ind = TRUE) - 1L
  
  edgelist <- to_integer(edgelist)
  endpoints <- to_integer(endpoints)
  new_barry_graph_cpp(N, edgelist[, 1L], edgelist[, 2L], n, endpoints)
  
}

#' @export
#' @examples
#' # Example with list of matrices
#' # Create friendship network data
#' friendship <- matrix(c(0, 1, 1, 0,
#'                       1, 0, 1, 1,
#'                       1, 1, 0, 0,
#'                       0, 1, 0, 0), nrow = 4, byrow = TRUE)
#' 
#' # Person 1's perception of the network
#' person1_view <- matrix(c(0, 1, 1, 1,
#'                         1, 0, 1, 0,
#'                         1, 1, 0, 1,
#'                         1, 0, 1, 0), nrow = 4, byrow = TRUE)
#' 
#' # Person 2's perception of the network  
#' person2_view <- matrix(c(0, 1, 0, 0,
#'                         1, 0, 1, 1,
#'                         0, 1, 0, 0,
#'                         0, 1, 0, 0), nrow = 4, byrow = TRUE)
#' 
#' # Create list with true network first, then perceptions
#' network_data <- list(friendship, person1_view, person2_view)
#' 
#' # Create barry graph
#' social_graph <- new_barry_graph(network_data)
#' print(social_graph)
#' 
#' # Using the Krackhardt data
#' # Load example network data
#' net1 <- matrix(c(0, 1, 1, 0,
#'                  1, 0, 0, 1,
#'                  1, 0, 0, 1,
#'                  0, 1, 1, 0), nrow = 4, byrow = TRUE)
#' 
#' net2 <- matrix(c(0, 1, 0, 0,
#'                  1, 0, 1, 1,
#'                  0, 1, 0, 0,
#'                  0, 1, 0, 0), nrow = 4, byrow = TRUE)
#' 
#' # Create barry graph with example data
#' example_networks <- list(net1, net2)
#' example_graph <- new_barry_graph(example_networks)
#' 
#' @rdname new_barry_graph
new_barry_graph.list <- function(x, ...) {
  
  # Checking all have the same size
  n <- unique(as.vector(sapply(x, dim)))
  if (length(n) != 1L)
    stop("All matrices in -x- should be of the same length.", call. = FALSE)
  
  # Should be of length n
  if (n < 1L)
    stop(
      "The size of the adjacency matrices in -x- should be at least 2L.",
      call. = FALSE
    )
  
  edgelists <- lapply(x, function(x.) {
    which(x. != 0L, arr.ind = TRUE)
  })
  
  # Adjusting indices
  for (i in seq_along(edgelists))
    edgelists[[i]] <- (edgelists[[i]] - 1L) + (i - 1L) * n
  
  edgelists <- do.call(rbind, edgelists)
  
  # Identifying the endpoints
  n_nets    <- length(x)
  endpoints <- cumsum(rep(n, times = n_nets - 1L)) + n
  edgelists <- to_integer(edgelists)
  endpoints <- to_integer(endpoints)
  if (any(edgelists < 0))
    stop("Edgelist cannot have negative values")
  if (any(endpoints < 0))
    stop("Endpoints cannot have negative values")
  
  # Creating the edgelist
  new_barry_graph_cpp(n * n_nets, edgelists[, 1], edgelists[, 2], n, endpoints)
  
}

#' Print Barry Graph
#' 
#' @description
#' Print method for barry_graph objects.
#' 
#' @param x A barry_graph object.
#' @param ... Additional arguments passed to print (currently ignored).
#' 
#' @return
#' Invisibly returns the input object. Called for its side effect of printing.
#' 
#' @examples
#' # Create a simple network example
#' net1 <- matrix(c(0, 1, 0,
#'                  1, 0, 1,
#'                  0, 1, 0), nrow = 3, byrow = TRUE)
#' 
#' net2 <- matrix(c(0, 1, 1,
#'                  1, 0, 0,
#'                  1, 0, 0), nrow = 3, byrow = TRUE)
#' 
#' # Create barry graph
#' graph <- new_barry_graph(list(net1, net2))
#' 
#' # Print the graph (shows summary information)
#' print(graph)
#' 
#' # The print method is called automatically
#' graph
#' 
#' @export
print.barry_graph <- function(x, ...) {
  suppressWarnings(print_barry_graph_cpp(x))
}