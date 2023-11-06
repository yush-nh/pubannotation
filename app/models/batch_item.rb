class BatchItem
  MAX_SIZE_TRANSACTION = 5000

  attr_reader :annotation_transaction

  def initialize
    @annotation_transaction = []
    @sourcedb_sourceids_index = DocumentSourceIndex.new
  end

  def <<(annotation_collection)
    @annotation_transaction << annotation_collection.annotations
    @sourcedb_sourceids_index.merge annotation_collection.sourcedb_sourceid_index
  end

  def enough?
    transaction_size > MAX_SIZE_TRANSACTION
  end

  def sourcedb_sourceids_indexes
    @sourcedb_sourceids_index.values
  end

  private

  def transaction_size
    @annotation_transaction.map do |annotations|
      annotations.map do |annotation|
        annotation[:denotations].present? ? annotation[:denotations].size : 0
      end.sum
    end.sum
  end
end
