class DocumentEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)
    DocumentEmbeddingService.new(document).call
  end
end
