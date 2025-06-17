require "openai"

class ChatQueryService
  def initialize(query)
    @query = query
    @openai = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"], log_error: true)

    @pinecone = Pinecone::Client.new
    @index = @pinecone.index(ENV["PINECONE_INDEX"])
  end

  def call
    embedding = @openai.embeddings(
      parameters: {
        model: "text-embedding-ada-002",
        input: @query
      }
    )["data"][0]["embedding"]

    results = @index.query(
      vector: embedding,
      top_k: 5,
      include_metadata: true
    )["matches"]

    context = results.map do |match|
      metadata = match["metadata"] || {}
      title = metadata["issuance_no"] || "[Untitled]"
      text_snippet = metadata["text"] || "[no text]"
      chunk_index = metadata["chunk_index"] || "?"
      score = match["score"] ? " (score: #{'%.2f' % match['score']})" : ""
      "#{title} (chunk #{chunk_index})#{score}:\n#{text_snippet}"
    end.join("\n\n")

    begin
      completion = @openai.chat(
        parameters: {
          model: "gpt-4",
          messages: [
            { role: "system", content: "You are an expert answering ONLY based on provided context. If unsure, say 'I don’t know.'" },
            { role: "user", content: "Context:\n#{context}\n\nQuestion: #{@query}" }
          ]
        }
      )
    rescue Faraday::BadRequestError => e
      Rails.logger.error "OpenAI 400 BadRequest: #{e.response.inspect}"
      raise
    end

    completion.dig("choices", 0, "message", "content")
  end
end
