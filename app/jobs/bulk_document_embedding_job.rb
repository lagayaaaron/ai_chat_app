class BulkDocumentEmbeddingJob < ApplicationJob
  queue_as :default

  def perform
    Document.find_each do |document|
      DocumentEmbeddingJob.perform_later(document.id)
    end
  end
end
