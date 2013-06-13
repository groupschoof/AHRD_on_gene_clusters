class ClusterAnnotation

  attr_accessor :cluster_size, :cluster_interpro_families, :cluster_interpro_others

  def initialize(cluster_size)
    @cluster_size = cluster_size
    @cluster_interpro_families = Hash.new
    @cluster_interpro_others = Hash.new
  end

  def annotate_interpro_instance(interpro_id, cluster_interpro_score_hash)
    if cluster_interpro_score_hash[interpro_id]
      cluster_interpro_score_hash[interpro_id] += (1.to_f / @cluster_size.to_f)
    else
      cluster_interpro_score_hash[interpro_id] = (1.to_f / @cluster_size.to_f)
    end
  end

  def add_interpro_annotation(interpro_id, path_2_interpro_db_csv_file = nil)
    interpro_instance = Interpro.interpro_instance(interpro_id, path_2_interpro_db_csv_file)
    if interpro_instance
      cluster_interpro_score_hash = 
        ('Family' == interpro_instance.type ?
        @cluster_interpro_families : @cluster_interpro_others)

      annotate_interpro_instance(interpro_id, cluster_interpro_score_hash)
    else
      puts "WARNING: Could not find Interpro-ID '#{interpro_id}' in Database!"
    end
  end

  def high_scoring_interpro_annotations(interpro_annotation_hash)
    high_score = interpro_annotation_hash.values.max
    # return
    (interpro_annotation_hash.map do |interpro_id, score|
      {:interpro_id => interpro_id, :score => score } if score >= high_score
    end).compact
  end

  def filter_ancestors(ipr_families_arr, path_2_interpro_db_csv_file = nil)
    all_interpro_ids = ipr_families_arr.map { |ipr_annotation| ipr_annotation[:interpro_id] }

    ipr_families_arr.each do |ipr_annotation|
      ipr_id = ipr_annotation[:interpro_id]
      score = ipr_annotation[:score]
      possible_ancestors = Array.new(all_interpro_ids)
      possible_ancestors.delete(ipr_id)
      possible_ancestors.each do |poss_ancestor_id|
        ipr_inst = Interpro.interpro_instance(ipr_id, path_2_interpro_db_csv_file)
        ipr_families_arr.delete(
          poss_ancestor_id
        ) if ipr_inst.ancestor(poss_ancestor_id)
      end  
    end  
    # return filtered
    ipr_families_arr
  end

  def human_readable_description(threshold_score, path_2_interpro_db_csv_file = nil)
    hrd = ''

    high_scoring_interpro_families = high_scoring_interpro_annotations(
      @cluster_interpro_families
    )
    high_scoring_interpro_families = filter_ancestors(
      high_scoring_interpro_families, 
      path_2_interpro_db_csv_file
    ) if high_scoring_interpro_families.length > 1

    high_scoring_interpro_others = high_scoring_interpro_annotations(
      @cluster_interpro_others
    )

    if((! high_scoring_interpro_families.empty?) && 
       high_scoring_interpro_families.first[:score] >= threshold_score)
      hrd += ClusterAnnotation.get_interpro_list_hrd(
        high_scoring_interpro_families,
        path_2_interpro_db_csv_file
      )
    else 
      if ! high_scoring_interpro_families.empty?
        hrd += ClusterAnnotation.get_interpro_list_hrd(
          high_scoring_interpro_families,
          path_2_interpro_db_csv_file
        )
      end
      if ! high_scoring_interpro_others.empty?
        #hrd += ",\n" if hrd.length > 0
        hrd += ClusterAnnotation.get_interpro_list_hrd(
          high_scoring_interpro_others,
          path_2_interpro_db_csv_file
        )
      end
    end
  end

  def self.get_interpro_list_hrd(interpro_hashes, path_2_interpro_db_csv_file = nil)
    hrd = ''
    if interpro_hashes && ! interpro_hashes.empty?
      interpro_hashes.each do |ipr_id_score_hash|
        hrd += get_interpro_instance_hrd(
          ipr_id_score_hash[:interpro_id],
          ipr_id_score_hash[:score],
          path_2_interpro_db_csv_file
        )
      end  
    end
    # return
    hrd
  end

  def self.get_interpro_instance_hrd(interpro_id, score, path_2_interpro_db_csv_file = nil)
    ipr_inst = Interpro.interpro_instance(interpro_id, path_2_interpro_db_csv_file)
    # return
    "[AHRD-Score #{format("%0.2f", score)}]\t#{interpro_id}\t#{ipr_inst.type}\t#{ipr_inst.name}\n"
  end
end
