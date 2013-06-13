#!/opt/share/local/users/hallab/Ruby/ruby_1_8_7/bin/ruby

require 'rubygems'
require 'erb'

puts "Generating shell-scripts running AHRD for each chunk of gene-clusters."
puts "Important NOTE: AHRD is going to use INTERPRO_DB stored IN MEMORY!"
puts "This is applicable for chunks of gene-clusters."
puts "In order to run AHRD on single gene-clusters, use CSV-File as INTERPRO_DB!"

template = ERB.new <<-ERB
#!/opt/share/local/users/hallab/Ruby/ruby_1_8_7/bin/ruby

require "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/v1_0_for_omcl_clusters/AHRDmain/AHRD_for_gene_clusters.rb"

analysis = AHRD_for_gene_clusters.new(
    "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/interpro_30.xml",
    "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/ParentChildTreeFile.txt"
)

analysis.add_annotated_organism('vitis', '/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/VitisV1_INTERPRO27.0_SIMAP.txt')
analysis.add_annotated_organism('rap2', '/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/RiceRAP2_INTERPRO27.0_SIMAP.txt')
analysis.add_annotated_organism('athalT9', '/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/AthalTAIR9_INTERPRO27.0_SIMAP.txt')
analysis.add_annotated_organism('TomatoITAG_A2.30V2.1', '/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/all_interpro_results.csv')

analysis.load_ortho_mcl_gene_clusters('<%= ortho_mcl_file %>')
analysis.assign_interpro_hrd_2_clusters("/home/proj_pcb/ITAG/pipe001/batch012/ahrd/output/cluster_hrds/")

puts "AHRD was successfully executed on Gene-Cluster-Chunk <%= index %>!"
ERB

# Generate CHUNKS of gene-clusters
no_chunks = 60

File.open("/home/proj_pcb/ITAG/pipe001/batch012/ahrd/bsub_cmnds.sh", 'w') do |out_file|

  out_file.write("#!/bin/sh\n\n\n")

  File.open(
    "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/ortho_mcl_results/tomA2.30V2.1_athT9_rap2_vit_OrthoMCL_29Oct10.out", 
    'r'
  ) do |omcl_result_file|

    omcl_clusters = omcl_result_file.lines.to_a
    chunk_size = (omcl_clusters.length.to_f / no_chunks.to_f).ceil

    60.times do |index|

      omcl_clusters_chunk = omcl_clusters[index * chunk_size, chunk_size]

      ortho_mcl_file = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/omcl_cluster_files/#{index}_omcl_chunk.txt"
      File.open(ortho_mcl_file, 'w') do |f|
        f.write(omcl_clusters_chunk.join(''))
      end
      ahrd_omcl_cluster_script = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/omcl_cluster_files/run_ahrd_on_cluster_#{index}.rb"
      File.open(ahrd_omcl_cluster_script, 'w') do |f|
        f.write(template.result(binding)) 
      end
      bsub_err = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/output/cluster_hrds/run_ahrd_on_cluster_#{index}_bsub.err"
      bsub_out = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/output/cluster_hrds/run_ahrd_on_cluster_#{index}_bsub.out"
      out_file.write("bsub -m ubuntu -q normal -g /ahrd_gene_clusters -o #{bsub_out} -e #{bsub_err} #{ahrd_omcl_cluster_script};\n")
    end
  end
end

