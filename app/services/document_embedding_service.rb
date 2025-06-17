class DocumentEmbeddingService
  MAX_TOKENS = 1000

  def initialize(document)
    @document = document
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"], log_error: true)
    @pinecone = Pinecone::Client.new
    @index = @pinecone.index(ENV["PINECONE_INDEX"])
  end

  def call
    sanitized_content = sanitize_content(@document.content)
    return log_skip("Content is blank") if sanitized_content.blank?

    delete_existing_chunks

    chunks = chunk_text(sanitized_content, MAX_TOKENS)

    chunks.each_with_index do |chunk_text, i|
      chunk_id = generate_chunk_id(i + 1)

      log_info("Generating embedding for chunk #{chunk_id}")
      embedding = get_embedding(chunk_text)

      if embedding
        @index.upsert(
          vectors: [ {
            id: chunk_id,
            values: embedding,
            metadata: {
              document_id: @document.id,
              issuance_no: @document.issuance_no,
              doc_date: @document.doc_date,
              chunk_index: i + 1,
              text: chunk_text
            }
          } ]
          )
        log_success("Uploaded chunk #{chunk_id} to Pinecone")
      else
        log_error("Failed to generate embedding for chunk #{chunk_id}")
      end
    end

    log_success("Document #{@document.id} processed (#{chunks.size} chunks)")
  end

  def self.delete_document_embeddings(document_id)
    new(Document.new(id: document_id)).delete_existing_chunks
  end

  private

  def generate_chunk_id(index)
    "#{@document.sgid}_#{index}"
  end

  def delete_existing_chunks
    filter = { document_id: @document.id }
    @index.delete(filter: filter)
    log_info("Deleted existing chunks for document #{@document.id}")
  rescue => e
    log_error("Failed to delete chunks for document #{@document.id}: #{e.message}")
  end

  def sanitize_content(content)
    return "" if content.blank?
    Nokogiri::HTML(content).text
  end

  def get_embedding(text)
    response = @client.embeddings(
      parameters: {
        model: "text-embedding-ada-002",
        input: text
      }
    )
    response["data"][0]["embedding"]
  rescue => e
    log_error("OpenAI error (doc #{@document.id}): #{e.class} - #{e.message}")
    nil
  end

  def chunk_text(text, max_tokens)
    max_chars = max_tokens * 4
    text.scan(/.{1,#{max_chars}}/m)
  end

  def log_info(message)
    Rails.logger.info(message)
    puts message
  end

  def log_success(message)
    Rails.logger.info(message)
    puts message
  end

  def log_error(message)
    Rails.logger.error(message)
    puts message
  end

  def log_skip(reason)
    log_info("Skipped document #{@document.id}: #{reason}")
  end
end
