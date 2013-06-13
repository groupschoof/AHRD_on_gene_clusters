#!/opt/share/local/users/hallab/Ruby/ruby_1_8_7/bin/ruby

require File.expand_path('../../interpro.rb', __FILE__)

Interpro.initialize_db(
  "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/interpro_30.xml",
  "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/ParentChildTreeFile.txt"
)

#puts Interpro::INTERPRO_DB.inspect
ipr_db_fl = "/home/proj_pcb/ITAG/pipe001/batch012/ahrd/input/interpro/interpro_30/interpro_30_pcb_db.csv"
Interpro.write_interpro_db(ipr_db_fl)

# Test read instances:
ipr_inst = Interpro.interpro_instance('IPR018090', ipr_db_fl)
puts "Parent ok? #{ipr_inst.parent_id == 'IPR000053'}"
puts "Name ok? #{ipr_inst.name == 'Pyrimidine-nucleoside phosphorylase, bacterial/eukaryotic'}"
puts "Type ok? #{ipr_inst.type == 'Family'}"

# Test find ancestor
ipr_inst = Interpro.interpro_instance('IPR013465')
puts "Should not be ancestor? #{ipr_inst.ancestor('IPR017712').nil?}"
puts "Should not be ancestor? #{ipr_inst.ancestor('IPR013466').nil?}"
puts "Should be ancestor? #{! ipr_inst.ancestor('IPR018090').nil?}"
puts "Should be ancestor? #{! ipr_inst.ancestor('IPR000053').nil?}"
