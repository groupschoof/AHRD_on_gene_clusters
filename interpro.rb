class Interpro

  require 'rubygems'
  require 'nokogiri'
  require 'open3'

  # CLASS-Constant
  INTERPRO_DB = Hash.new

  attr_accessor :parent_id, :type, :name, :short_name, :abstract

  def self.initialize_db(path_2_interpro_db_xml_file)
    interpro_db = Nokogiri::XML(IO.read(path_2_interpro_db_xml_file))

    interpro_db.xpath('//interpro').each do |interpro_entry|
      ipr_id = interpro_entry.attribute('id').value
      ipr = Interpro.new
      ipr.short_name = interpro_entry.attribute('short_name').value if interpro_entry.attribute('short_name')
      ipr.type = interpro_entry.attribute('type').value if interpro_entry.attribute('type')
      ipr.name = interpro_entry.xpath('name').first.content
      ipr.abstract = interpro_entry.xpath('abstract').first.content
      if parent_list_entry = interpro_entry.xpath('parent_list').first
        ipr.parent_id = parent_list_entry.xpath('rel_ref').first.attribute('ipr_ref').value
      end
      Interpro::INTERPRO_DB[ipr_id] = ipr
    end  
  end

  def self.write_interpro_db(path_2_interpro_db_csv_file)
    File.open(path_2_interpro_db_csv_file, 'w') do |f|
      # Write Headline
      f.write("interpro-id\tshort-name\tname\ttype\tparent-id\tabstract\n")
      # Write content
      Interpro::INTERPRO_DB.each_pair do |interpro_id, ipr_inst|
        f.write("#{interpro_id}\t#{ipr_inst.short_name}\t#{ipr_inst.name}\t#{ipr_inst.type}\t#{ipr_inst.parent_id}\t#{ipr_inst.abstract}\n")
      end      
    end
  end

  def self.interpro_instance(interpro_id, path_2_interpro_db_csv_file = nil)
    ipr_inst = nil
    if path_2_interpro_db_csv_file
      ipr_inst = read_interpro_instance(interpro_id, path_2_interpro_db_csv_file)
    else
      ipr_inst = Interpro::INTERPRO_DB[interpro_id]
    end
    # return
    ipr_inst
  end

  def self.read_interpro_instance(interpro_id, path_2_interpro_db_csv_file)
    result = nil
    Open3.popen3("grep -e '^#{interpro_id}' #{path_2_interpro_db_csv_file}") { |stdin, stdout, stderr| result = stdout.readlines }
    ipr_entry = result.first.split(/\t+/).map { |ipr_attr| ipr_attr.strip }
    ipr_inst = Interpro.new
    ipr_inst.short_name = ipr_entry[1]
    ipr_inst.name = ipr_entry[2]
    ipr_inst.type = ipr_entry[3]
    ipr_inst.parent_id = ipr_entry[4]
    ipr_inst.abstract = ipr_entry[5]
    # return
    ipr_inst
  end

  def self.find_ancestor(ipr_inst, ancestor_ipr_id, path_2_interpro_db_csv_file = nil)
    parent_ipr_inst = nil
    if ipr_inst.parent_id == ancestor_ipr_id
      parent_ipr_inst = interpro_instance(ancestor_ipr_id, path_2_interpro_db_csv_file)
    elsif ipr_inst.parent_id == nil
      parent_ipr_inst = nil
    else 
      # Recursion
      parent_ipr_inst = find_ancestor(
        interpro_instance(ipr_inst.parent_id, path_2_interpro_db_csv_file),
        ancestor_ipr_id,
        path_2_interpro_db_csv_file
      )
    end
  end

  def ancestor(ancestor_ipr_id, path_2_interpro_db_csv_file = nil)
    Interpro.find_ancestor(
      self, ancestor_ipr_id, path_2_interpro_db_csv_file
    )
  end
end
