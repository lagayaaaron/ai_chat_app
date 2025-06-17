class Document < ApplicationRecord
  validates :issuance_no, presence: true, uniqueness: true
  validates :content, presence: true

  after_save :enqueue_embedding_job
  after_destroy :delete_embeddings

  private

  def enqueue_embedding_job
    DocumentEmbeddingJob.perform_later(id)
  end

  def delete_embeddings
    DocumentEmbeddingService.delete_document_embeddings(id)
  end
end
