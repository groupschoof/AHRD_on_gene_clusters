require File.join(File.expand_path(File.dirname(__FILE__)), 'AHRD_for_gene_clusters.rb')

puts "Usage: ruby generate_ahrd_for_gene_cluster_run.rb [path_to_ahrd_run_file.rb]"

ahrd_run_file = nil
ahrd_run_file = ARGV[0] if ARGV[0]

if ahrd_run_file
  AHRD_for_gene_clusters.generate_analysis(ahrd_run_file)
else 
  AHRD_for_gene_clusters.generate_analysis()
end

puts "Open the newly created ahrd-run-file.rb and adopt the code to your input-data."


