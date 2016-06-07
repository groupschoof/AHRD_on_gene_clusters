# Function ensured data-sets to be loaded, whenever this package is loaded.
.onLoad <- function( libname = find.package( "AHRD.on.gene.clusters" ), pkgname = "AHRD.on.gene.clusters" ) {
    data( "ipr_and_families", package = "AHRD.on.gene.clusters" )
    message("\nMAKE SURE THAT YOUR PROTEIN-INTERPRO-ANNOTATIONS ARE UNIQUE BEFORE YOU USE AHRD.on.gene.clusters\n")
}
