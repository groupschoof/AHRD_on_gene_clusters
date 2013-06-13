#!/opt/share/local/users/hallab/Ruby/ruby_1_8_7/bin/ruby

require File.expand_path('../../AHRD_for_gene_clusters.rb',  __FILE__)

analysis_run = lambda do |path_2_hrd_result_folder, path_2_interpro_db_csv_file|
  analysis = AHRD_for_gene_clusters.new(
    "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/interpro_30.xml",
    "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/ParentChildTreeFile.txt",
    path_2_interpro_db_csv_file
  )

  analysis.add_annotated_organism('vitis', File.expand_path('../VitisV1_INTERPRO27.0_SIMAP.txt', __FILE__))
  analysis.add_annotated_organism('rap2', File.expand_path('../RiceRAP2_INTERPRO27.0_SIMAP.txt', __FILE__))
  analysis.add_annotated_organism('athalT9', File.expand_path('../AthalTAIR9_INTERPRO27.0_SIMAP.txt', __FILE__))
  analysis.add_annotated_organism('TomatoITAG_A2.30V2.1', File.expand_path('../all_interpro_results.csv', __FILE__))

  analysis.load_ortho_mcl_gene_clusters(File.expand_path('/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/omcl_cluster_files/ORTHOMCL8249.txt', __FILE__))
  analysis.assign_interpro_hrd_2_clusters(path_2_hrd_result_folder)
end

path_2_hrd_test_result_folder = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/v1_0_for_omcl_clusters/AHRDmain/test/test_ahrd_for_gene_clusters_out/memory_db/"
analysis_run.call(path_2_hrd_test_result_folder, nil)
puts "Analysis ran without exceptions using IN-MEMORY INTERPRO_DB!"

path_2_hrd_test_result_folder = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/v1_0_for_omcl_clusters/AHRDmain/test/test_ahrd_for_gene_clusters_out/csv_db/"
path_2_test_as_ipr_db_csv_file = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/interpro_30_pcb_db.csv"
analysis_run.call(path_2_hrd_test_result_folder, path_2_test_as_ipr_db_csv_file)
puts "Analysis ran without exceptions using INTERPRO_DB-CSV-File!"

puts "Done"
