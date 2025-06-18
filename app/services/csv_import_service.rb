require "csv"

class CsvImportService
  def initialize(file_path)
    @file_path = file_path
  end

  def import
    CSV.foreach(@file_path, headers: true) do |row|
      begin
        Document.create!(
          issuance_no: row["issuance_no"],
          doc_date: row["doc_date"] ? DateTime.parse(row["doc_date"]) : nil,
          content: row["content"]
        )
      rescue => e
        Rails.logger.error("Error importing row: #{row.to_h}, Error: #{e.message}")
      end
    end
  end

  def self.import_async(file_path)
    CsvImportJob.perform_later(file_path)
  end
end
