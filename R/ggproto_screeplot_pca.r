#' Creates a data frame of the variance explained by the Principal Components.
#' 
#' @examples 
#' dat <- tourr::flea[, 1:6]
#' df_scree_pca(data = dat)
df_scree_pca <- function(data, 
                         do_rescale = TRUE){
  if(do_rescale == TRUE) data <- tourr::rescale(data)
  data <- as.data.frame(data)
  p <- ncol(data)
  
  ## PCA VARIANCE EXPLAINED
  pca_obj <- prcomp(data)
  data.frame(pc_num = factor(paste0("PC", 1:p), levels = paste0("PC", 1:p)),
             PC_var = pca_obj$sdev^2 / sum(pca_obj$sdev^2),
             cumsum_var = cumsum(pca_obj$sdev^2) / sum(pca_obj$sdev^2)
  )
}

#' Creates a screeplot of the variance explained by the Principal Components.
#' 
#' @examples 
#' dat <- tourr::flea[, 1:6]
#' palette(RColorBrewer::brewer.pal(12, "Dark2")) 
#' ggplot2::ggplot() + ggproto_screeplot_pca(dat)
#' 
#' ggplot2::ggplot() +
#'   ggproto_screeplot_pca(data = dat) +
#'   ggplot2::theme_bw()

ggproto_screeplot_pca <- function(data,
                                  do_rescale = TRUE){
  df_screetable_pca <- df_scree_pca(data, do_rescale)
  
  lab_fill <- "PC variance"
  lab_col  <- "Cummulative variance"
  ## List of ggproto's that is addable to a ggplot object.
  list(
    ## Individual feature bars
    ggplot2::geom_bar(ggplot2::aes(x = pc_num, y = PC_var, fill = lab_fill),
                      df_screetable_pca, stat = "identity"),
    ## Cummulative feature line
    ggplot2::geom_line(ggplot2::aes(x = pc_num, y = cumsum_var,
                                    color = lab_col, group = 1),
                       df_screetable_pca, lwd = 1.2),
    ggplot2::geom_point(ggplot2::aes(x = pc_num, y = cumsum_var, 
                                     color = lab_col), 
                        df_screetable_pca, shape = 18, size = 4),
    ## Titles and colors
    ggplot2::labs(x = "Principal component", y = "Variance"),
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30)),
    ggplot2::scale_fill_manual(values = palette()[1]),
    ggplot2::scale_colour_manual(values = palette()[2])
  )
}
