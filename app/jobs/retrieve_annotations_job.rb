class RetrieveAnnotationsJob < Struct.new(:project, :url, :options)
	include StateManagement

	def perform
		@job.update_attribute(:num_items, 1)
    @job.update_attribute(:num_dones, 0)

    begin
      result = project.make_request(:get, url)
      annotations_col = (result.class == Array) ? result : [result]
	    annotations_col.each_with_index do |annotations, i|
	      raise RuntimeError, "Invalid annotation JSON object." unless annotations.respond_to?(:has_key?)
	      Annotation.normalize!(annotations, options[:prefix])
	    end

	    messages = project.store_annotations_collection(annotations_col, options)
	    messages.each{|message| @job.messages << Message.create(message)}
    rescue RestClient::ExceptionWithResponse => e
      if e.response.code == 404 #Not Found
				options[:try_times] -= 1
      	if options[:try_times] > 0
	        priority = project.jobs.unfinished.count
	        delayed_job = Delayed::Job.enqueue RetrieveAnnotationsJob.new(project, url, options), priority: priority, queue: :general, run_at: options[:retry_after].seconds.from_now
	        Job.create({name:"Retrieve annotations", project_id:project.id, delayed_job_id:delayed_job.id})
					@job.messages << Message.create({body: "Not available. Will try #{options[:try_times]} more time(s)."})
	      else
					@job.messages << Message.create({body: "Retrieval of annotation failed."})
	      end
      else
				@job.messages << Message.create({body: e.message})
      end
    rescue => e
			@job.messages << Message.create({body: e.message})
    end

		@job.update_attribute(:num_dones, 1)
	end
end