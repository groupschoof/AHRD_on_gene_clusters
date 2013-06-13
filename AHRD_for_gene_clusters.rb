# Assigns Human Readable Descriptions to Gene-Clusters.
# Those Gene-Clusters could be provided as OrthoMCL-Clusters.
#
# As for now only Cluster-wide Interpro-Annotations are used.
class AHRD_for_gene_clusters

  require File.expand_path('../annotated_gene', __FILE__)
  require File.expand_path('../cluster_annotation', __FILE__)
  require File.expand_path('../interpro', __FILE__)
  require 'set'

  attr_accessor :gene_clusters, :cluster_annotations, :path_2_interpro_db_csv_file

  def initialize(
    path_2_interpro_db_xml_file = nil,
    path_2_interpro_db_csv_file = nil
  )
    # Initialize Interpro-Database
    Interpro.initialize_db(
      path_2_interpro_db_xml_file 
    ) if (path_2_interpro_db_xml_file)

    # Use a CSV-File as intermediate Interpo-Database, if requested by init-argument.
    # The usage of such an intermediate DB should ALWAYS be used 
    # in parallel execution of AHRD on gene-clusters
    @path_2_interpro_db_csv_file = path_2_interpro_db_csv_file
    Interpro.write_interpro_db(
      @path_2_interpro_db_csv_file
    ) if @path_2_interpro_db_csv_file

    @gene_clusters = Hash.new 
    @cluster_annotations = Hash.new
  end

  def add_annotated_organism(organism, path_2_interpro_annotation_file)
    annotated_genes = Hash.new

    File.open(path_2_interpro_annotation_file, 'r') do |f|
      f.each do |gene_annotation|
        gene_accession, interpro_id = gene_annotation.split(/\s+/)
        gene_accession.strip!
        interpro_id.strip!
        if annotated_genes[gene_accession]
          annotated_genes[gene_accession].add?(interpro_id)
        else
          annotated_genes[gene_accession] = Set.new([interpro_id])
        end
      end  
    end

    AnnotatedGene.organism_annotations[organism] = annotated_genes

    # return
    true
  end

  # Takes a path to an Ortho-MCL-Result-File and
  # initializes @gene_clusters with it's content.
  # Sanitizes the OrthoMCL-Cluster-Names, just using the unique identifier,
  # not the number of taxa nor genes included.
  def load_ortho_mcl_gene_clusters(path_2_ortho_mcl_result_file)
    File.open(path_2_ortho_mcl_result_file, 'r') do |omcl_res_file|
      omcl_res_file.each do |omcl_cluster|

        # Initialize input
        cluster_name, cluster_genes = omcl_cluster.split(':')
        cluster_name = cluster_name.strip.sub(/\(.+\)$/, '')

        if cluster_name && cluster_genes
          # Add cluster ...
          @gene_clusters[cluster_name] = Array.new

          # ... and it's genes:
          cluster_genes.strip.split(/\s/).each do |gene|
            if m = /(\S+)\((\S+)\)/.match(gene)
              @gene_clusters[cluster_name] << AnnotatedGene.new(m[1].strip, m[2].strip)
            else
              raise "ERROR: Could not extract gene-accession and organism from '#{gene}'" 
            end
          end  
        else
          puts "WARNING: Could not generate meaningful gene-cluster from input-line '#{omcl_cluster}'!"
        end

      end
    end
    # return
    true
  end

  def assign_interpro_hrd_2_clusters(path_2_ahrd_result_folder)
    # Iterate over each Gene-Cluster and assign 
    # best matching human readable descriptions:
    @gene_clusters.each_pair do |cluster_name, annotated_genes|
      ca = ClusterAnnotation.new(annotated_genes.length)
      annotated_genes.each do |anot_gene|
        anot_gene.annotated_interpro_ids.each do |interpro_id|
          ca.add_interpro_annotation(interpro_id, @path_2_interpro_db_csv_file)
        end  
      end  

      # Just saved for usage in Interactive-Console or Script,
      # that wants to access the results for further processing.
      @cluster_annotations[cluster_name] = ca

      # Write output to files
      write_cluster_hrd_to_file(
        cluster_name, 
        ca, 
        path_2_ahrd_result_folder, 
        @path_2_interpro_db_csv_file
      )
    end      

    # return
    true
  end

  def write_cluster_hrd_to_file(cluster_name, cluster_annotation, path_2_ahrd_result_folder, path_2_interpro_db_csv_file = nil)
    File.open(File.join(path_2_ahrd_result_folder, "#{cluster_name}.txt"), 'w') do |hrd_file|
      if hrd = cluster_annotation.human_readable_description(0.5, @path_2_interpro_db_csv_file)
        hrd_file.write("#{hrd}\n")
      end
    end
  end

  def self.generate_analysis(analysis_file="ahrd_on_gene_clusters_#{Time.now.strftime('%d_%b_%Y')}.rb")
      out = <<-RUBY
require '#{File.expand_path(File.join(File.dirname(__FILE__), 'AHRD_for_gene_clusters.rb'))}'

# Put in the paths to the interpro-db-xml-file and the parent-child-file.
# See ftp://ftp.ebi.ac.uk/pub/databases/interpro/
analysis = AHRD_for_gene_clusters.new(path_2_interpro_db_xml_file)

# Put in the organism-names and paths to their Interpro-Annotation-Files
analysis.add_annotated_organism(organism_1, path_2_interpro_annotation_file_1)
analysis.add_annotated_organism(organism_2, path_2_interpro_annotation_file_2)

# Put in the path to the OrthoMCL-Result-File:
analysis.load_ortho_mcl_gene_clusters(path_2_ortho_mcl_result_file)

# Run the analysis, writing a single result-file for each Gene-Cluster into the
# selected output-folder:
analysis.assign_interpro_hrd_2_clusters(path_2_ahrd_result_folder)
      RUBY

    File.open(analysis_file, 'w') do |f|
      f.write(out)
    end

    # return
    true
  end

end
