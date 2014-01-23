# encoding: UTF-8
module AnnotationsHelper
  def get_annotations (project, doc, options = {})
    if doc.present?
      hdenotations = doc.hdenotations(project, options)
      hinstances = doc.hinstances(project, options)
      hrelations = doc.hrelations(project, options)
      hmodifications = doc.hmodifications(project, options)
      text = doc.body
      if (options[:encoding] == 'ascii')
        asciitext = get_ascii_text (text)
        sequence_alignment = SequenceAlignment.new(text, asciitext, [["Δ", "delta"], [" ", " "], ["−", "-"], ["–", "-"], ["′", "'"], ["’", "'"]])
        # sequence_alignment = Aligner.new(text, asciitext)
        hdenotations = sequence_alignment.transform_denotations(hdenotations)
        # hdenotations = adjust_denotations(hdenotations, asciitext)
        text = asciitext
      end

      if (options[:discontinuous_annotation] == 'bag')
        # TODO: convert to hash representation
        hdenotations, hrelations = bag_denotations(hdenotations, hrelations)
      end

      annotations = Hash.new
      # if doc.sourcedb == 'PudMed'
      #   annotations[:pmdoc_id] = doc.sourceid
      # elsif doc.sourcedb == 'PMC'
      #   annotations[:pmcdoc_id] = doc.sourceid
      #   annotations[:div_id] = doc.serial
      # end
      
      # project
      if project.present?
        annotations[:project] = project[:name]
      end 
      # doc
      annotations[:source_db] = doc.sourcedb
      annotations[:source_id] = doc.sourceid
      annotations[:division_id] = doc.serial
      annotations[:section] = doc.section
      annotations[:text] = text
      # doc.relational_models
      annotations[:denotations] = hdenotations if hdenotations
      annotations[:instances] = hinstances if hinstances
      annotations[:relations] = hrelations if hrelations
      annotations[:modifications] = hmodifications if hmodifications
      annotations
    else
      nil
    end
  end

  def bag_denotations (denotations, relations)
    tomerge = Hash.new

    new_relations = Array.new
    relations.each do |ra|
      if ra[:pred] == '_lexChain'
        tomerge[ra[:obj]] = ra[:subj]
      else
        new_relations << ra
      end
    end
    idx = Hash.new
    denotations.each_with_index {|ca, i| idx[ca[:id]] = i}

    mergedto = Hash.new
    tomerge.each do |from, to|
      to = mergedto[to] if mergedto.has_key?(to)
      fca = denotations[idx[from]]
      tca = denotations[idx[to]]
      tca[:span] = [tca[:span]] unless tca[:span].respond_to?('push')
      tca[:span].push (fca[:span])
      denotations.delete_at(idx[from])
      mergedto[from] = to
    end

    return denotations, new_relations
  end
  
  def project_annotations_zip_link_helper(project_name, options = {})
    file_path = "#{Denotation::ZIP_FILE_PATH}#{project_name}.zip"
    
    if File.exist?(file_path) == true
      # when ZIP file exists 
      html = link_to "annotation.zip", "/annotations/#{project_name}.zip", :class => 'button'
      html += content_tag :span, "#{File.ctime(file_path).strftime("#{t('controllers.shared.last_modified_at')}:%Y-%m-%d %T")}", :class => 'zip_time_stamp'
    else
      # when ZIP file deos not exists 
      delayed_job_tasks = ActiveRecord::Base.connection.execute('SELECT * FROM delayed_jobs').select{|delayed_job| delayed_job['handler'].include?(project_name) && delayed_job['handler'].include?('save_annotation_zip')}
      if delayed_job_tasks.blank?
        # when delayed_job exists
        link_to t('controllers.annotations.create_zip'), project_annotations_path(project_name, :delay => true), :class => 'button', :confirm => t('controllers.annotations.confirm_create_zip')
      else
        # delayed_job does not exists
        t('views.shared.zip.delayed_job_present')
      end
    end    
  end  
end
