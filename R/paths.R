#' CE Path
#'
#' @return returns path for consensus ec data
#' @export
path_ce <- function(){

  cepath <- system.file("data/raw/ce", package = "localforecastrep")
  return(cepath)

}
