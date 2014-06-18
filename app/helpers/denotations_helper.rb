module DenotationsHelper
  def denotations_count_helper(project, options = {})
    if params[:action] == 'spans'
      if project.present?
        options[:doc].denotations.where(:project_id => project.id).within_spans(params[:begin], params[:end]).size
      else
        options[:doc].denotations.within_spans(params[:begin], params[:end]).size
      end
    else      
      if project.present?
        if options[:doc].present?
          if params[:controller] == 'projects' && options[:doc].sourcedb == 'PMC'
            project.denotations.project_pmcdoc_denotations(options[:sourceid]).count
          else  
            Denotation.project_denotations_count(project.id, options[:doc].denotations)
          end
        else
          project.denotations_count
        end
      else
        options[:doc].denotations.size
      end   
    end
  end
  
  def spans_link_url_helper(doc, denotation)
    if doc.has_divs?
      Rails.application.routes.url_helpers.doc_sourcedb_sourceid_divs_spans_url(doc.sourcedb, doc.sourceid, doc.serial, denotation[:span][:begin], denotation[:span][:end])
    else
      Rails.application.routes.url_helpers.doc_sourcedb_sourceid_spans_url(doc.sourcedb, doc.sourceid, denotation[:span][:begin], denotation[:span][:end])
    end
  end

  def spans_link_helper(doc, denotation)
    link_to "#{denotation[:span][:begin]}-#{ denotation[:span][:end]}", spans_link_url_helper(doc, denotation) 
  end

  def get_project_denotations(projects, doc, params)
    project_denotations = Array.new
    projects.each do |project|
      project_denotations << {:project => project, :denotations => get_annotations(project, doc, :spans => {:begin_pos => params[:begin], :end_pos => params[:end]})[:denotations]}
    end
    return project_denotations
  end
end
