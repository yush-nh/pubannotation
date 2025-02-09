class ImportAnnotationsJob < ApplicationJob
	include UseJobRecordConcern

	queue_as :general

	def perform(project, source_project_id, options = {})
		prepare_progress_record(1)

		count_shared_docs = case options[:mode]
		when :skip
			ActiveRecord::Base.connection.select_value <<~SQL.squish
				SELECT count(*)
				FROM project_docs AS target
				WHERE target.project_id=#{project.id}
				AND EXISTS (SELECT 1 FROM project_docs AS source WHERE source.project_id=#{source_project_id} AND source.doc_id = target.doc_id)
				AND target.denotations_num = 0 AND target.blocks_num = 0
			SQL
		else
			ActiveRecord::Base.connection.select_value <<~SQL.squish
				SELECT count(*)
				FROM project_docs AS target
				WHERE target.project_id=#{project.id}
				AND EXISTS (SELECT 1 FROM project_docs AS source WHERE source.project_id=#{source_project_id} AND source.doc_id = target.doc_id)
			SQL
		end

		raise "Importing annotations for more than 1M documents is prohibited for a performance issue." if count_shared_docs > 1000000
		raise "There is no shared document in the two projects." unless count_shared_docs > 0

		count_add_annotations, count_del_annotations = case options[:mode]
		when :skip
			project.import_annotations_from_another_project_skip(source_project_id)
		when :replace
			project.import_annotations_from_another_project_replace(source_project_id)
		when :add
			raise RuntimeError, "The 'Add' mode of importing annotations is disabled at the moment."
		when :merge
			raise RuntimeError, "The 'Merge' mode of importing annotations is disabled at the moment."
		else
			raise RuntimeError, "Unknown mode of importing annotations: #{options[:mode]}."
		end

		message = "#{count_add_annotations} annotations for #{count_shared_docs} doc(s) were imported" +
			(count_del_annotations > 0 ? ", after #{count_del_annotations} annotations were deleted." : '.')

		@job&.add_message body: message
		@job&.update_attribute(:num_dones, 1)
	end

	def job_name
		"Import annotations from the projects, #{resource_name}"
	end

	private

	def resource_name
		Project.find(self.arguments[1])&.name
	end
end