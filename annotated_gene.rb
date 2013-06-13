class AnnotatedGene

  require 'rubygems'
  require 'set'

  @@organism_annotations = Hash.new

  def self.organism_annotations
    @@organism_annotations
  end

  attr_accessor :accession, :organism, :annotated_interpro_ids

  def initialize(accession, organism)
    # Validate organism-name:
    raise "Missing Interpro-Annotation of organism '#{organism}'" unless @@organism_annotations[organism]

    @accession = accession
    @organism = organism
    @annotated_interpro_ids = 
      (@@organism_annotations[organism][accession] ?
       @@organism_annotations[organism][accession] : Set.new)
  end

end
