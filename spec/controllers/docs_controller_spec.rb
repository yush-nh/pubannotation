# encoding: utf-8
require 'spec_helper'

describe DocsController do
  describe 'index' do
    before do
      @project = FactoryGirl.create(:project)
      @project_doc = FactoryGirl.create(:doc, :sourcedb => 'PMC', :sourceid => 123)
      @project.docs << @project_doc  
      @source_db_id = Doc.all
      Doc.stub(:source_db_id).and_return(@source_db_id)
      @doc = FactoryGirl.create(:doc, :sourcedb => 'PubMed', :sourceid => 123)  
    end
    
    context 'when project present' do
      before do
        get :index, :project_id => @project.name
      end
      
      it 'should assign project' do
        assigns[:project].should eql(@project)
      end
      
      it 'should assign search_project_docs_path as @search_path' do
        assigns[:search_path].should eql search_project_docs_path(@project.name)
      end
      
      it 'should assign @source_docs' do
        assigns[:source_docs].should =~ @source_db_id
      end
    end    
    
    context 'when project blank' do
      before do
        get :index
      end
      
      it 'should assign search_docs_path as @search_path' do
        assigns[:search_path].should eql search_docs_path
      end
            
      it 'should assign @source_docs' do
        assigns[:source_docs].should =~ @source_db_id
      end
    end    
  end
  
  describe 'records' do
    before do
      @doc = FactoryGirl.create(:doc, :sourceid => 'sourceid', :serial => 1, :section => 'section')
    end
    
    context 'when params[:project_id] exists' do
      before do
        @project = FactoryGirl.create(:project)
        @project_id = 'project id'
        @get_project_notice = 'get project notice'
      end
      
      context 'when get_project returns project' do
        before do
          controller.stub(:get_project).and_return([@project, @get_project_notice])
          get :records, :project_id => @project_id
        end
        
        it 'should render template' do
          response.should render_template('records')
        end
      end

      context 'when get_project does not returns project' do
        before do
          controller.stub(:get_project).and_return([nil, @get_project_notice])
        end
        
        context 'when format html' do
          before do
            get :records, :project_id => @project_id
          end
          
          it 'should render template' do
            response.should render_template('records')
          end
          
          it 'set get_project notice as flash[:notice]' do
            flash[:notice].should eql(@get_project_notice)
          end
        end
        
        context 'when format json' do
          before do
            get :records, :format => 'json', :project_id => @project_id
          end
          
          it 'should return status 422' do
            response.status.should eql(422)
          end
        end
        
        context 'when format text' do
          before do
            get :records, :format => 'txt', :project_id => @project_id
          end
          
          it 'should return status 422' do
            response.status.should eql(422)
          end
        end
      end
    end

    context 'when params[:project_id] does not exists' do
      context 'when format html' do
        before do
          get :records
        end
        
        it 'should render template' do
          response.should render_template('records')
        end
      end

      context 'when format json' do
        before do
          get :records, :format => 'json'
        end
        
        it 'should render @docs as json' do
          response.body.should eql(assigns[:docs].to_json)
        end
      end

      context 'when format text' do
        before do
          get :records, :format => 'txt'
        end
        
        it 'should return zpi' do
          response.content_type.should eql("application/zip")
        end
      end
    end
  end
  
  describe 'sourcedb_index' do
    before do
      @project = FactoryGirl.create(:project)
      # create docs belongs to project
      @project_doc_1 = FactoryGirl.create(:doc, :sourcedb => "sourcedb1")
      @project.docs << @project_doc_1
      @project_doc_2 = FactoryGirl.create(:doc, :sourcedb => "sourcedb2")
      @project.docs << @project_doc_2
      # create docs not belongs to project
      2.times do
        FactoryGirl.create(:doc, :sourcedb => 'sdb')
      end
      # create docs not belongs to project sourced db nil
      2.times do
        FactoryGirl.create(:doc, :sourcedb => nil)
      end
      # create docs not belongs to project sourced db ''
      2.times do
        FactoryGirl.create(:doc, :sourcedb => '')
      end
    end

    context 'when params[:project_id] present' do
      before do
        get :sourcedb_index, :project_id => @project.name
      end  
      
      it 'should include project.docs sourcedb' do
        assigns[:docs].collect{|doc| doc.sourcedb}.uniq.should =~ @project.docs.collect{|doc| doc.sourcedb}
      end    
    end

    context 'when params[:project_id] blank' do
      before do
        get :sourcedb_index
      end  
      
      it 'should not contatin blank sourcedb' do
        assigns[:docs].select{|doc| doc.sourcedb == nil || doc.sourcedb == ''}.should be_blank
      end    
    end
  end
  
  describe 'sourceid_index' do
    before do
      @project = FactoryGirl.create(:project, :name => 'project name')
      @sourcedb = 'source db'
      @project_doc = FactoryGirl.create(:doc, :sourcedb => @sourcedb, :sourceid => 123)
      @project.docs << @project_doc  
      @project_doc_2 = FactoryGirl.create(:doc, :sourcedb => 'sdb', :sourceid => 123)
      @project.docs << @project_doc_2  
      @doc = FactoryGirl.create(:doc, :sourcedb => @sourcedb, :sourceid => 123)
    end
    
    context 'when params[:project_id] present' do
      before do
        get :sourceid_index, :project_id => @project.name, :sourcedb => @sourcedb
      end
      
      it 'should assigns project.docs which sourcedb match' do
        assigns[:source_docs].should =~ @project.docs.where(['sourcedb = ?', @sourcedb])
      end
    end
    
    context 'when params[:project_id] blank' do
      before do
        get :sourceid_index, :sourcedb => @sourcedb
      end
      
      it 'should assigns docs which sourcedb match' do
        assigns[:source_docs].should =~ Doc.where(['sourcedb = ?', @sourcedb])
      end
    end
  end
  
  describe 'search' do
    context 'without pagination' do
      before do
        @pubmed = FactoryGirl.create(:doc, :sourcedb => 'PubMed', :serial => 0, :sourceid => 234)
        @selial_1 = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 1, :sourceid => 123)
        @sourceid_123 = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 123)
        @sourceid_1234 = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 1234)
        @sourceid_1123 = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 1123)
        @sourceid_234 = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 234)
      end
      
      context 'when project_id blank' do
        context 'when params[:sourceid] and params[:body] is nil' do
          before do
            @sourcedb = 'PMC'
            get :search, sourcedb: 'PMC'
          end  
          
          it 'should set sourcedb docs as @source_docs' do
            assigns[:source_docs].should =~ Doc.find_all_by_sourcedb(@sourcedb)
          end
          
          it 'should not include sourcedb not match' do
            assigns[:source_docs].should_not include @pubmed
          end
        end
        
        context 'when params[:sourceid] present' do
          before do
            get :search, :sourceid => '123'
          end
          
          it 'should not include source id like not match' do
            assigns[:source_docs].should_not include(@pubmed)
          end
          
          it 'should include source id like match' do
            assigns[:source_docs].should include(@selial_1)
          end
          
          it 'should include sourceid include 123' do
            assigns[:source_docs].should include(@sourceid_123)
          end
    
          it 'should include sourceid include 123' do
            assigns[:source_docs].should include(@sourceid_1234)
          end
    
          it 'should include sourceid include 123' do
            assigns[:source_docs].should include(@sourceid_1123)
          end
    
          it 'should not include sourceid not include 123' do
            assigns[:source_docs].should_not include(@sourceid_234)
          end
        end
        
        context 'when params[:body] present' do
          before do
            @sourceid_123_test = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 123, :body => 'test')
            @sourceid_1234_test = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 1234, :body => 'testmatch')
            @sourceid_234_test = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 234, :body => 'matchtest')
            @sourceid_123_est = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 123, :body => 'est')
            get :search, :body => 'test'
          end
          
          it 'should include  body contains body' do
            assigns[:source_docs].should include(@sourceid_123_test)
          end
          
          it 'should include body contains body' do
            assigns[:source_docs].should include(@sourceid_1234_test)
          end
          
          it 'should include body contains body' do
            assigns[:source_docs].should include(@sourceid_234_test)
          end
          
          it 'should include body contains body' do
            assigns[:source_docs].should_not include(@sourceid_123_est)
          end
        end
        
        context 'when params[:sourceid] and params[:body] present' do
          before do
            @sourceid_1_body_test = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 1, :body => 'test')
            @sourceid_1_body_test_and = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 1, :body => 'testand')
            @sourceid_1_body_nil = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 1, :body => nil)
            @sourceid_2_body_test = FactoryGirl.create(:doc, :sourcedb => 'PMC', :serial => 0, :sourceid => 2, :body => 'test')
            get :search, :sourceid => 1, :body => 'test'
          end
          
          it 'should include sourceid and body matches' do
            assigns[:source_docs].should include(@sourceid_1_body_test)
          end
          
          it 'should include sourceid and body matches' do
            assigns[:source_docs].should include(@sourceid_1_body_test_and)
          end
          
          it 'should not include body does not match' do
            assigns[:source_docs].should_not include(@sourceid_1_body_nil)
          end
          
          it 'should not include sourceid does not match' do
            assigns[:source_docs].should_not include(@sourceid_2_body_test)
          end
        end
      end
      
      context 'when project_id prsent' do
        before do
          @project = FactoryGirl.create(:project)
          @project.docs << @selial_1
          @project.reload
          get :search, :sourcedb => @selial_1.sourcedb, :project_id => @project.name
        end
        
        it 'should docs condition match included in project' do
          assigns[:source_docs].should =~ [@selial_1]
        end
      end
      
      context 'when docs not found' do
        before do
          get :search, :sourcedb => 'invalid'
        end
        
        it 'should set flash[:notice]' do
          flash[:notice].should be_present
        end
      end
    end
  end
  
  describe 'show' do
    before do
      @doc = FactoryGirl.create(:doc, :sourcedb => 'sd', :sourceid => '123456')  
    end
    
    context 'when params id present' do
      context 'when format html' do
        before do
          get :show, :id => @doc.id
        end
        
        it 'should render template' do
          response.should render_template('show')
        end
      end
      
      context 'when format json' do
        before do
          get :show, :format => 'json', :id => @doc.id
        end
        
        it 'should render @doc as json' do
          response.body.should eql(@doc.to_json)
        end
      end
    end
    
    context 'when params sourcedb sourceid present' do
      context 'when docs.length == 1' do
        context 'when format html' do
          before do
            get :show, :sourcedb  => @doc.sourcedb, :sourceid => @doc.sourceid 
          end
          
          it 'should render template' do
            response.should render_template('show')
          end
        end
        
        context 'when format json' do
          before do
            get :show, :format => 'json', :sourcedb  => @doc.sourcedb, :sourceid => @doc.sourceid 
          end
          
          it 'should render @doc as json' do
            response.body.should eql(@doc.to_json)
          end
        end
      end
    end
    
    describe 'when @doc present' do
      before do
        @project = 'project'
        @noice = 'notice'
        controller.stub(:get_project).and_return([@project, @notice])
        @projects = 'projects'
        controller.stub(:get_projects).and_return(@projects)
        get :show, :id => @doc.id
      end
      
      it 'should assign @doc' do
        assigns[:doc].should eql @doc
      end
      
      it 'should assign @project' do
        assigns[:project].should eql @project
      end
      
      it 'should assign @projects' do
        assigns[:projects].should eql @projects
      end
    end
    
    describe 'when @doc blank docs present' do
      before do
        @noice = 'notice'
        FactoryGirl.create(:doc, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid.to_s)  
      end
      
      context 'when @project present' do
        before do
          @project = FactoryGirl.create(:project)
          controller.stub(:get_project).and_return([@project, @notice])
          get :show, :sourcedb  => @doc.sourcedb, :sourceid => @doc.sourceid 
        end
        
        it 'should render template' do
          response.should redirect_to(index_project_sourcedb_sourceid_divs_docs_path(@project.name, @doc.sourcedb, @doc.sourceid))
        end
      end
      
      context 'when @project blank' do
        before do
          controller.stub(:get_project).and_return([nil, @notice])
          get :show, :sourcedb  => @doc.sourcedb, :sourceid => @doc.sourceid 
        end
        
        it 'should render template' do
          response.should redirect_to(doc_sourcedb_sourceid_divs_index_path)
        end
      end
    end
  end
  
  describe 'annotations_index' do
    before do
      controller.stub(:get_docspec).and_return(nil)
    end
    
    context 'when @doc present' do
      before do
        @doc = FactoryGirl.create(:doc)
        @project_denotations = 'project_denotations'
        @doc.stub(:project_denotations).and_return(@project_denotations)
        controller.stub(:get_doc).and_return([@doc, nil])
        @get_annotations_for_json = {:root => 'get_annotations_for_json'}
        controller.stub(:get_annotations_for_json).and_return(@get_annotations_for_json)
      end
      
      context 'when format html' do
        before do
          get :annotations_index, :id => @doc.id   
        end
        
        it 'should assign @doc.project_denotatios as @denotations' do
          assigns[:denotations].should eql(@project_denotations)
        end
        
        it 'should render template' do
          response.should render_template('docs/annotations_index')
        end
      end
      
      context 'when format json' do
        before do
          get :annotations_index, :id => @doc.id, :format => 'json'   
        end
        
        it 'should render template' do
          response.body.should eql(@get_annotations_for_json.to_json)
        end
      end
    end
  end
  
  describe 'annotations' do
    before do
      @project = FactoryGirl.create(:project, :name => 'project_name')
      controller.stub(:get_project).and_return(@project, 'notice')
      @doc = FactoryGirl.create(:doc, :sourcedb => 'sourcedb', :sourceid => 123456)
      controller.stub(:get_doc).and_return(@doc, 'notice')
      @projects = [@project]
      controller.stub(:get_projects).and_return(@projects)
      @spans = 'spans' 
      @prev_text = 'prevx text'
      @next_text = 'next text'
      Doc.any_instance.stub(:spans).and_return([@spans, @prev_text, @next_text])
      @annotations ={
        :base_text => "text",
        :denotations => "denotations",
        :instances => "instances",
        :relations => "relations",
        :modifications => "modifications"
      }
      controller.stub(:get_annotations_for_json).and_return(@annotations)
    end
    
    context 'when params[:project_id] present' do
      before do
       get :annotations, :project_id => @project.name, :id => @doc.id, :begin => 1, :end => 10
      end
      
      it 'should assign @doc' do
        assigns[:doc].should eql(@doc)
      end
      
      it 'should_not assign @projects' do
        assigns[:projects].should be_nil
      end
      
      it 'should assign @spans' do
        assigns[:spans].should eql(@spans)
      end
      
      it 'should assign @prev_text' do
        assigns[:prev_text].should eql(@prev_text)
      end
      
      it 'should assign @next_text' do
        assigns[:next_text].should eql(@next_text)
      end
      
      it 'should assign @denotations' do
        assigns[:denotations].should eql(@annotations[:denotations])
      end
      
      it 'should assign @relations' do
        assigns[:relations].should eql(@annotations[:relations])
      end
      
      it 'should assign @modifications' do
        assigns[:modifications].should eql(@annotations[:modifications])
      end
        
      it 'sould render template' do
        response.should render_template('annotations')
      end
    end
    
    
    context 'when params[:project_id] blank' do
      context 'when format html' do
        context 'when params[:id] present' do
          before do
            get :annotations, :id => @doc.id, :begin => 1, :end => 10
          end
          
          it 'should not assign @project' do
            assigns[:project].should be_nil
          end
          
          it 'should assign @doc' do
            assigns[:doc].should eql(@doc)
          end
          
          it 'sould render template' do
            response.should render_template('annotations')
          end
        end

        context 'when params[:id] is nil and params[:sourcedb] and params[:sourceid] present' do
          context 'when docs.has_divs? is false' do
            before do
              get :annotations, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid, :begin => 0, :end => 10
            end
            
            it 'should not assign @project' do
              assigns[:project].should be_nil
            end
            
            it 'should assign @doc' do
              assigns[:doc].should eql(@doc)
            end
            
            it 'sould render template' do
              response.should render_template('annotations')
            end
          end

          context 'when docs.has_divs? is true' do
            before do
              get :annotations, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid, :begin => 0, :end => 10
            end
            
            it 'should not assign @project' do
              assigns[:project].should be_nil
            end
            
            it 'should assign @doc' do
              assigns[:doc].should eql(@doc)
            end
            
            it 'sould render template' do
              response.should render_template('annotations')
            end
          end
        end
      end

      context 'when format json' do
        before do
          get :annotations, :format => :json, :id => @doc.id, :begin => 1, :end => 10
        end
        
        it 'sould render json' do
          response.body.should eql(@annotations.to_json)
        end
      end
    end
  end

  
  describe 'spans_index' do
    before do
      @project = FactoryGirl.create(:project)
      controller.stub(:get_project).and_return([@project, nil])
      @doc = FactoryGirl.create(:doc, :sourceid => '12345', :sourcedb => 'PubMed', :serial => 0)
      controller.stub(:get_doc).and_return([@doc, nil])
    end
    
    context 'when project_id present' do
      before do
        @denotation_1 = {:span => 'span1'}
        @denotation_2 = {:span => 'span2'}
        @denotations = [@denotation_1, @denotation_1, @denotation_2]
        controller.stub(:get_annotations).and_return({:denotations => @denotations})
        get :spans_index, :project_id => @project.name, :id => @doc.sourceid
      end
      
      it 'should assign @project' do
        assigns[:project].should eql(@project)  
      end
      
      it 'should assign @doc' do
        assigns[:doc].should eql(@doc)  
      end
      
      it 'should assign unique denotation hashes as @denotations' do
        assigns[:denotations].should =~ @denotation_1.map{|key, value| {key.to_s => value}} + @denotation_2.map{|key, value| {key.to_s => value}}
      end
      
      it 'should render template' do
        response.should render_template('docs/spans_index')
      end
    end
    
    context 'when project_id blank' do
      context 'when params id present' do
        before do
          @denotation = FactoryGirl.create(:denotation)
          @doc.denotations << @denotation
          get :spans_index, :id => @doc.sourceid
        end
        
        it 'should assign @doc' do
          assigns[:doc].should eql(@doc)  
        end
        
        it 'should assign @denotations' do
          assigns[:denotations].should eql([{"id" => @denotation.hid, "span" => {"begin" => @denotation.begin, "end" => @denotation.end}, "obj" => @denotation.obj}])  
        end
        
        it 'should render template' do
          response.should render_template('docs/spans_index')
        end
      end
      
      context 'when params id blank' do
        before do
          @denotation = FactoryGirl.create(:denotation)
          @doc.denotations << @denotation
        end
        
        context 'when docs.lengs == 1' do
          before do
            get :spans_index, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid
          end
          
          it 'should assign @doc' do
            assigns[:doc].should eql(@doc)  
          end
          
          it 'should assign @denotations' do
            assigns[:denotations].should eql([{"id" => @denotation.hid, "span" => {"begin" => @denotation.begin, "end" => @denotation.end}, "obj" => @denotation.obj}])  
          end
          
          it 'should render template' do
            response.should render_template('docs/spans_index')
          end
        end

        context 'when docs.lengs > 1' do
          before do
            @doc_2 = FactoryGirl.create(:doc, :sourceid => @doc.sourceid, :sourcedb => @doc.sourcedb, :serial => @doc.serial.to_i + 1 )
            get :spans_index, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid, :div_id => @doc.serial
          end
          
          it 'should assign @doc' do
            assigns[:doc].should eql(@doc)  
          end
          
          it 'should assign @denotations' do
            assigns[:denotations].should eql([{"id" => @denotation.hid, "span" => {"begin" => @denotation.begin, "end" => @denotation.end}, "obj" => @denotation.obj}])  
          end
          
          it 'should render template' do
            response.should render_template('docs/spans_index')
          end
        end
      end
    end
  end
  
  describe 'spans' do
    before do
      @body = 'doc body'
      @doc = FactoryGirl.create(:doc, :sourceid => '12345', :body => @body)
      @project = 'project'
      @project_1 = FactoryGirl.create(:project)
      @projects = [@project_1]
      controller.stub(:get_project).and_return([@project, nil])
      @doc.stub(:spans_projects).and_return(@projects)
      controller.stub(:get_doc).and_return([@doc, nil])
      @spans = 'SPANS'
      @prev_text = 'PREV'
      @next_text = 'NEXT'
      @doc.stub(:spans).and_return([@spans, @prev_text, @next_text])
    end
    
    context 'when params[:project_id] present' do
      context 'when format html' do
        before do
          get :spans, :project_id => 1, :id => @doc.sourceid, :begin => 1, :end => 5
        end
        
        it 'should assign @project' do
          assigns[:project].should eql(@project)
        end
        
        it 'should not assign' do
          assigns[:projects].should be_nil
        end
        
        it 'should assign @doc' do
          assigns[:doc].should eql(@doc)
        end
        
        it 'should assign @spans' do
          assigns[:spans].should eql(@spans)
        end
        
        it 'should assign @prev_text' do
          assigns[:prev_text].should eql(@prev_text)
        end
        
        it 'should assign @next_text' do
          assigns[:next_text].should eql(@next_text)
        end
        
        it 'should render template' do
          response.should render_template('docs/spans')
        end
      end

      context 'when format json' do
        before do
          get :spans, :format => 'json', :project_id => 1, :id => @doc.sourceid, :begin => 1, :end => 5
        end
      end
    end
    
    context 'when params[:project_id] blank' do
      before do
        @project_denotation = 'project denotations'
        @project_denotations = {:denotations => @project_denotation}
        controller.stub(:get_annotations).and_return(@project_denotations)
        get :spans, :id => @doc.sourceid, :begin => 1, :end => 5
      end
      
      it 'should not assign @project' do
        assigns[:project].should be_nil
      end
      
      it 'should assign @projects' do
        assigns[:projects].should eql(@projects)
      end
      
      it 'should assign @project_denotations' do
        assigns[:project_denotations].should eql([{'project' => @project_1, 'denotations' => @project_denotation}])
      end
    end
  end
  
  describe 'new' do
    context 'when format html' do
      before do
        get :new
      end
      
      it 'should buid new doc' do
        assigns[:doc].new_record?.should be_true
      end
      
      it 'should render template' do
        response.should render_template('new')
      end
    end
    
    context 'when format json' do
      before do
        get :new, :format => 'json'
      end
      
      it 'should render @doc as json' do
        response.body.should eql(assigns[:doc].to_json)
      end
    end
  end
  
  describe 'edit' do
    before do
      @doc = FactoryGirl.create(:doc)
      get :edit, :id => @doc.id
    end
    
    it 'should render template' do
      response.should render_template('edit')
    end
    
    it 'find Doc correctly' do
      assigns[:doc].should eql(@doc)
    end
  end
  
  describe 'create' do
    context 'when save successfully' do
      context 'when format html' do
        context 'when project blank' do
          before do
            post :create
          end
          
          it 'should redirect to doc_path' do
            response.should redirect_to(doc_path(assigns[:doc]))
          end
        end
        
        context 'when project present' do
          before do
            @project = FactoryGirl.create(:project)
            controller.stub(:get_project).and_return(@project)
            post :create, :project_id => @project.id
          end
          
          it 'should redirect to doc_path' do
            response.should redirect_to(project_doc_path(@project.name, assigns[:doc]))
          end
        end
      end

      context 'when format json' do
        before do
          post :create, :format => 'json'
        end
        
        it 'should render @doc as json' do
          response.body.should eql(assigns[:doc].to_json)
        end
        
        it 'should return status created' do
          response.status.should eql(201)
        end
        
        it 'should return doc_path as location' do
          response.location.should eql("http://test.host#{doc_path(assigns[:doc])}")
        end
      end
    end

    context 'when save unsuccessfully' do
      context 'when format html' do
        before do
          Doc.any_instance.stub(:save).and_return(false)
          post :create
        end
        
        it 'should render new action' do
          response.should render_template('new')
        end
      end

      context 'when format json' do
        before do
          Doc.any_instance.stub(:save).and_return(false)
          post :create, :format => 'json'
        end
        
        it 'should return status 422' do
          response.status.should eql(422)
        end
      end
    end
  end
  
  describe 'create_project_docs' do
    before do
      @project = FactoryGirl.create(:project)
    end
    
    context 'when params[:project_id] present' do
      context 'when project present' do
        before do
          controller.stub(:get_project).and_return([@project, nil])
        end
        
        context 'when num_added > 0' do
          before do
            @num_added = 5
            @project.stub(:add_docs).and_return([0, @num_added, 0])
          end
          
          context 'when format html' do
            before do
              get :create_project_docs, :project_id => @project.name, :sourcedb => 'PMC'
            end
            
            it 'should set number of documents added to project flash[:notice]' do
              flash[:notice].should eql(I18n.t('controllers.docs.create_project_docs.added_to_document_set', :num_added => @num_added, :project_name => @project.name))
            end
            
            it 'should redirect project_path' do
              response.should redirect_to(project_docs_path(@project.name))
            end
          end
          
          context 'when format json' do
            before do
              get :create_project_docs, :format => 'json', :project_id => @project.name, :sourcedb => 'PMC'
            end
            
            it 'should return status 201' do
              response.status.should eql(201)
            end
            
            it 'should return project_path as location' do
              response.location.should eql project_path(@project.name)
            end
          end
        end
        
        context 'when num_added == 0 and num_created > 0' do
          before do
            @num_added = 0
            @num_created = 1
            @project.stub(:add_docs).and_return([@num_created, @num_added, 0])
          end
          
          context 'when format html' do
            before do
              get :create_project_docs, :project_id => @project.name, :sourcedb => 'PMC'
            end
            
            it 'should set number of documents added to project flash[:notice]' do
              flash[:notice].should eql(I18n.t('controllers.docs.create_project_docs.created_to_document_set', :num_created => @num_created, :project_name => @project.name))
            end
            
            it 'should redirect project_path' do
              response.should redirect_to(project_docs_path(@project.name))
            end
          end
        end
        
        context 'when num_added == 0' do
          before do
            @num_added = 0
            @project.stub(:add_docs).and_return([0, @num_added, 0])
          end
          
          context 'when format html' do
            before do
              get :create_project_docs, :project_id => @project.name, :sourcedb => 'PMC'
            end
            
            it 'should set number of documents added to project flash[:notice]' do
              flash[:notice].should eql(I18n.t('controllers.docs.create_project_docs.added_to_document_set', :num_added => @num_added, :project_name => @project.name))
            end
            
            it 'should redirect home_path' do
              response.should redirect_to(home_path)
            end
          end
          
          context 'when format json' do
            before do
              get :create_project_docs, :format => 'json', :project_id => @project.name, :sourcedb => 'PMC'
            end
            
            it 'should return status 422' do
              response.status.should eql(422)
            end
          end
        end
        
        context 'when error raised' do
          before do
            @project.stub(:add_docs).and_raise('eoor')
            get :create_project_docs, :project_id => @project.name, :sourcedb => 'PMC'
          end
          
          it 'should redirect project_path' do
            response.should redirect_to(project_docs_path(@project.name))
          end
        end
      end

      context 'when project nil' do
        before do
          get :create_project_docs, :project_id => 'invalid'
        end
              
        it 'should set flash[:notice]' do
          flash[:notice].should eql(I18n.t('controllers.pmcdocs.create.annotation_set_not_specified'))
        end
        
        it 'should redirect home_path' do
          response.should redirect_to(home_path)
        end     
      end
    end
  end
  
  describe 'update' do
    before do
      @doc = FactoryGirl.create(:doc)
    end
    
    context 'when update successfully' do
      before do
        @params_doc = {:body => 'body'}
      end
      
      context 'when format html' do
        before do
          post :update, :id => @doc.id, :doc => @params_doc
        end
        
        it 'should redirect to doc_path' do
          response.should redirect_to(doc_path(@doc))
        end
      end

      context 'when format json' do
        before do
          post :update, :format => 'json', :id => @doc.id, :doc => @params_doc
        end
        
        it 'should return blank header' do
          response.header.should be_blank
        end
      end
    end
    
    context 'when update unsuccessfully' do
      before do
        @params_doc = {:body => 'body'}
        Doc.any_instance.stub(:update_attributes).and_return(false)
      end
      
      context 'when format html' do
        before do
          post :update, :id => @doc.id, :doc => @params_doc
        end
        
        it 'should render edit action' do
          response.should render_template('edit')
        end
      end

      context 'when format json' do
        before do
          post :update, :format => 'json', :id => @doc.id, :doc => @params_doc
        end
        
        it 'should return status 422' do
          response.status.should eql(422)
        end
      end
    end
  end
  
  describe 'destroy' do
    before do
      @doc = FactoryGirl.create(:doc)
    end
    
    context 'when params[:project_id] present' do
      context 'format html' do
        before do
          @project = FactoryGirl.create(:project)
          @project.docs << @doc
          @project.reload
        end
        
        describe 'before post' do
          it 'doc should included in project.docs' do
            @project.docs.should include @doc
          end
        end
        
        describe 'adter post' do
          before do
            delete :destroy, :id => @doc.id, :project_id => @project.name
            @project.reload
          end  
          
          it 'doc should not included in project.docs' do
            @project.docs.should_not include @doc
          end
        
          it 'should not destory doc' do
            Doc.find_by_id(@doc.id).should be_present
          end
          
          it 'should redirect to docs_url' do
            response.should redirect_to(records_project_docs_path(@project.name))
          end
        end
        
      end
    end
    
    context 'when params[:project_id] blank' do
      context 'format html' do
        before do
          delete :destroy, :id => @doc.id
        end
        
        it 'should destory doc' do
          Doc.find_by_id(@doc.id).should be_nil
        end
        
        it 'should redirect to docs_url' do
          response.should redirect_to(docs_url)
        end
      end
  
      context 'format json' do
        before do
          delete :destroy, :format => 'json', :id => @doc.id
        end
        
        it 'should return blank header' do
          response.header.should be_blank
        end
      end
    end
  end
end