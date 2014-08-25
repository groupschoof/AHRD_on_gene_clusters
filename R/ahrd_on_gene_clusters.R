parseInterProTag <- function(xml.node) {
    # Use library XML to parse a single InterPro tag and extract ID,
    # SHORT.NAME, PARENT-, and CONTAINS-list. 
    #
    # Args:
    #  xml.node : A single entry of the result of calling getNodeSet(...) on the
    #             InterPro XML document 
    #
    # Returns: A list with three attributes 'ID', 'PARENTS', and 'CONTAINS'.
    #
    ipr.id <- xmlGetAttr(xml.node, "id")
    ipr.prnts <- as.character(lapply(getNodeSet(xml.node, "./parent_list/rel_ref"), 
        function(x) xmlGetAttr(x, "ipr_ref")))
    ipr.contains <- as.character(lapply(getNodeSet(xml.node, "./contains/rel_ref"), 
        function(x) xmlGetAttr(x, "ipr_ref")))
    ipr.name <- as.character(lapply(getNodeSet(xml.node, "./name"),
        function(x) xmlValue(x, recursive=FALSE, trim=TRUE)))
    list(ID = ipr.id, PARENTS = ipr.prnts, CONTAINS = ipr.contains, TYPE = xmlGetAttr(xml.node, 
        "type"), SHORT.NAME = xmlGetAttr(xml.node, "short_name"))
} 

parseInterProXML <- function(path.2.xml) {
    # Read and parse the InterPro XML database.
    #
    # Args:
    #  path.2.xml : The file path to the interpro.xml document
    #
    # Returns: A named list of lists, each of which is the result of parsing a
    # single InterPro XML node with function parseInterProTag(...).
    #    
    ipr.db <- lapply(getNodeSet(xmlInternalTreeParse(path.2.xml), "//interpro"), 
        parseInterProTag)
    names(ipr.db) <- as.character(mclapply(ipr.db, function(x) x$ID))
    # return
    ipr.db
} 

interProRecursion <- function(ipr.id, relship.slot = "PARENTS", interpro.database = ipr.db) {
    # Recursively traverses InterPro entries held in argument
    # 'interpro.database' and finds all entries related to argument 'ipr.id'
    # through relation 'relship.slot'. In case of PARENTS all parents and parents
    # of parents are returned, in case of CONTAINS all contained and contained in
    # contained are.
    #
    # Args:
    #  ipr.id            : The InterPro accession to start the recursion from,
    #                      for example 'IPR000003'
    #  relship.slot      : Either 'PARENTS' or 'CONTAINS', default is 'PARENTS'
    #  interpro.database : The named list containing the parsed contents of the
    #                      XML interpro document. See parseInterProXML(...) for
    #                      details.
    #
    # Returns: A character vector of recursive PARENTS or CONTAINED InterPro
    # entries for the argument entry 'ipr.id'.
    #   
    ipr.lst <- interpro.database[[ipr.id]]
    if (!is.null(ipr.lst)) {
        if (!is.null(ipr.lst[[relship.slot]]) && length(ipr.lst[[relship.slot]]) > 
            0) {
            # Recursion:
            union(unlist(lapply(ipr.lst[[relship.slot]], interProRecursion, relship.slot = relship.slot, 
                interpro.database = interpro.database)), ipr.lst[[relship.slot]])
        }
    }
} 

filterInterProClusterAnnotations <- function( ipr.ids, interpro.database=ipr.db ) {
  # Reduce a set of InterPro accessions (IDs) to those not being contained by
  # others, and those not being parents of others. Hence give the 'most
  # informative' InterPro accessions of the argument 'ipr.ids'.
  #
  # Args:
  #  ipr.ids : Result of parsing the InterPro XML database with ''
  #
  # Returns: The character vector of InterPro accessions, that is the subset of
  # argument 'irp.ids' filtered as descibed above.
  #   
  ipr.discard <- unique(unlist(lapply(ipr.ids, function(x) union(interProRecursion(x, 
      relship.slot = "PARENTS", interpro.database = interpro.database), interProRecursion(x, 
      relship.slot = "CONTAINS", interpro.database = interpro.database)))))
  setdiff(ipr.ids, ipr.discard) 
}

annotateCluster <- function(fam, ipr.annos, interpro.database) {
    # Each gene family (cluster of amino acid sequences) has members that in
    # turn might have InterPro annotations in argument 'ipr.annos'. Those are
    # filtered in order to retain only those that are NOT contained in others and
    # those that are NOT parents of others. Here, "others" refers to InterPro
    # annotations found for genes of the cluster of course. The family 'fam' is
    # then assigned the most frequent InterPro family(s), if their respective
    # frequency is at least 0.5. If no such "frequent" InterPro family annotation
    # is found, the most frequent InterPro annotation regardless of its type are
    # used. In most cases these are of type domain.
    #
    # Args:
    #  fam               : A character vector of gene accessions
    #  ipr.annos         : A data.frame with - at least - two columns, the first
    #                      holding the gene accessions, and the second holding
    #                      the annotated InterPro entry
    #  interpro.database : The database of InterPro entries as parsed from the
    #                      interpro XML document "interpro.xml". The format is a
    #                      named list of named lists. See parseInterProXML(...)
    #                      for more details.
    #
    # Returns: A list of InterPro accessions to be interpreted as the argument
    # gene family's 'fam' annotation. The list includes the annotations'
    # frequency and short descriptions.
    #   
    all.ipr.annos <- ipr.annos[which(ipr.annos$V1 %in% fam), "V2"]
    fltrd.iprs <- filterInterProClusterAnnotations(all.ipr.annos, interpro.database = ipr.db)
    fltrd.iprs.fams <- fltrd.iprs[as.logical(lapply(fltrd.iprs, function(x) interpro.database[[x]]$TYPE == 
        "Family"))]
    smr <- summary(factor(all.ipr.annos[which(all.ipr.annos %in% fltrd.iprs)]))
    if (!is.null(smr) && length(smr) > 0) {
        ipr.freqs <- smr/length(fam)
        iprs <- if (!is.null(fltrd.iprs.fams) && length(fltrd.iprs.fams) > 0 && max(ipr.freqs[fltrd.iprs.fams], 
            na.rm = TRUE) >= 0.5) {
            ipr.fam.freqs <- ipr.freqs[fltrd.iprs.fams]
            names(ipr.fam.freqs[which(ipr.fam.freqs == max(ipr.fam.freqs, na.rm = TRUE))])
        } else {
            max.ipr.freq <- max(ipr.freqs, na.rm = TRUE)
            names(ipr.freqs[which(ipr.freqs == max.ipr.freq)])
        }
        list(most.frequent.IPRs = interpro.database[iprs], frequency = max(smr, na.rm = TRUE)/length(fam))
    } 
} 
